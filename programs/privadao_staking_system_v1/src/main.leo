import privadao_core_v1.aleo;
import privadao_governance_token_v1.aleo;

program privadao_staking_system_v1.aleo {
    // Constants
    const MAX_STAKING_BONUS_RATE: u64 = 20u64; // 20% maximum bonus
    const STAKING_BONUS_HALF_TIME: u32 = 365 * 24 * 60 * 60; // 1 year in seconds

    // Structs
    struct Stake {
        stake_owner: address,
        amount: u64,
        start_time: u32,
        duration: u32,
        last_claim_time: u32,
    }

    struct Delegation {
        delegator: address,
        delegatee: address,
        category: field,
        amount: u64,
        reputation: u64,
    }

    struct DelegateeReputation {
        delegatee_address: address,
        category: field,
        reputation_score: u64,
        proposals_supported: u32,
        proposals_succeeded: u32,
    }

    struct SlashingProposal {
        target: address,
        category: field,
        amount: i64,
        reason: field,
    }

    // Mappings
    mapping stakes: address => Stake;
    mapping delegatee_reputations: field => DelegateeReputation;
    mapping dao_statistics: field => u64;

    // Transitions
    transition stake_tokens(amount: u64, duration: u32, token: GovernanceToken) -> bool {
        assert(token.amount >= amount);
         finalize_stake_tokens(token.owner, amount, duration);
    }

    async function finalize_stake_tokens(owner: address, amount: u64, duration: u32) {
        let new_stake: Stake = Stake {
            stake_owner: owner,
            amount: amount,
            start_time: block.height,
            duration: duration,
            last_claim_time: block.height,
        };

        Mapping::set(stakes, owner, new_stake);

        // Update DAO statistics
        let total_staked: u64 = Mapping::get_or_use(dao_statistics, field("total_staked"), 0u64);
        Mapping::set(dao_statistics, field("total_staked"), total_staked + amount);
    }

   async transition unstake_tokens() -> GovernanceToken {
        return GovernanceToken { owner: self.caller, amount: 0u64 } then async function(self.caller);
    }

    async function unstake_tokens(caller: address) -> GovernanceToken {
        let stake: Stake = Mapping::get(stakes, caller);
        assert(block.height >= stake.start_time + stake.duration);

        let bonus: u64 = calculate_staking_bonus(stake, block.height);
        let total_amount: u64 = stake.amount + bonus;

        // Remove the stake
        Mapping::remove(stakes, caller);

        // Update DAO statistics
        let total_staked: u64 = Mapping::get(dao_statistics, field("total_staked"));
        Mapping::set(dao_statistics, field("total_staked"), total_staked - stake.amount);

        return GovernanceToken {
            owner: caller,
            amount: total_amount,
        };
    }

    transition claim_staking_rewards() -> u64 {
        return 0u64 then async function(self.caller);
    }

    async function claim_staking_rewards(caller: address) -> u64 {
        let  stake: Stake = Mapping::get(stakes, caller);
        let bonus: u64 = calculate_staking_bonus(stake, block.height);

        // Update last claim time
        stake.last_claim_time = block.height;
        Mapping::set(stakes, caller, stake);

        return bonus;
    }

    // Helper functions
    function calculate_staking_bonus(stake: Stake, current_time: u32) -> u64 {
        let time_staked: u32 = current_time - stake.last_claim_time;
        let total_staked: u64 = Mapping::get_or_use(dao_statistics, field("total_staked"), 0u64);
        let participation_factor: u64 = Mapping::get_or_use(dao_statistics, field("participation_rate"), 50u64); // 0-100 scale
        
        let base_bonus_rate: u64 = MAX_STAKING_BONUS_RATE * (1u64 - 2u64.pow(-time_staked / STAKING_BONUS_HALF_TIME));
        let adjusted_bonus_rate: u64 = (base_bonus_rate * participation_factor) / 100u64;
        let stake_weight: u64 = (stake.amount * 1000u64) / total_staked; // Stake weight out of 1000
        
        return (stake.amount * adjusted_bonus_rate * stake_weight) / 100000u64; // Scaled back down
    }

    // New transitions for delegation and reputation management
    transition delegate(delegatee: address, category: field, amount: u64) -> bool {
        return true then async function(self.caller, delegatee, category, amount);
    }

    async function delegate(delegator: address, delegatee: address, category: field, amount: u64) {
        let delegation: Delegation = Delegation {
            delegator: delegator,
            delegatee: delegatee,
            category: category,
            amount: amount,
            reputation: 0u64, // Initial reputation
        };

        let key: field = BHP256::hash_to_field(delegator + delegatee + category);
        Mapping::set(delegations, key, delegation);

        // Update delegatee reputation
        let rep_key: field = BHP256::hash_to_field(delegatee + category);
        let mut rep: DelegateeReputation = Mapping::get_or_use(delegatee_reputations, rep_key, DelegateeReputation {
            delegatee_address: delegatee,
            category: category,
            reputation_score: 0u64,
            proposals_supported: 0u32,
            proposals_succeeded: 0u32,
        });
        rep.reputation_score += amount;
        Mapping::set(delegatee_reputations, rep_key, rep);
    }

    transition update_delegatee_reputation(delegatee: address, category: field, change: i64) -> bool {
         async function_update_delegatee_reputation(delegatee, category, change);
    }

    async function async function_update_delegatee_reputation(delegatee: address, category: field, change: i64) {
        let key: field = BHP256::hash_to_field(delegatee + category);
        let mut rep: DelegateeReputation = Mapping::get(delegatee_reputations, key);
        rep.reputation_score = (rep.reputation_score as i64 + change) as u64;
        Mapping::set(delegatee_reputations, key, rep);
        return true 
    }

    async transition propose_slashing(target: address, category: field, amount: i64, reason: field) -> bool {
       async function_propose_slashing(target, category, amount, reason);
    }

    async function async function_propose_slashing(target: address, category: field, amount: i64, reason: field) {
        let proposal: SlashingProposal = SlashingProposal {
            target: target,
            category: category,
            amount: amount,
            reason: reason,
        };
        let key: field = BHP256::hash_to_field(target + category + (amount as field) + reason);
        Mapping::set(slashing_proposals, key, proposal);
         return true 
    }

    // View functions
    transition view_stake(user: address) -> Stake {
        async function_view_stake(user);
    }

    async function async function_view_stake(user: address) -> Stake {
        return Mapping::get_or_use(stakes, user, Stake {
            stake_owner: user,
            amount: 0u64,
            start_time: 0u32,
            duration: 0u32,
            last_claim_time: 0u32,
        });




    }

   async transition view_delegatee_reputation(delegatee: address, category: field) -> DelegateeReputation {
        return DelegateeReputation {
            delegatee_address: delegatee,
            category: category,
            reputation_score: 0u64,
            proposals_supported: 0u32,
            proposals_succeeded: 0u32,
        } then async function(delegatee, category);
    }

    async function view_delegatee_reputation(delegatee: address, category: field) -> DelegateeReputation {
        let key: field = BHP256::hash_to_field(delegatee + category);
        return Mapping::get_or_use(delegatee_reputations, key, DelegateeReputation {
            delegatee_address: delegatee,
            category: category,
            reputation_score: 0u64,
            proposals_supported: 0u32,
            proposals_succeeded: 0u32,
        });
    }
}