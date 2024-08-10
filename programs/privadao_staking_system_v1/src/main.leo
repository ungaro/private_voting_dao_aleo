    import privadao_core_v1.aleo;
    import privadao_governance_token_v1.aleo;

// The 'privadao_staking_system_v1' program.
program privadao_staking_system_v1.aleo {

 


    // New struct for staking
    struct Stake {
        owner: address,
        amount: u64,
        start_time: u32,
        duration: u32,
    }

    // Modified struct for delegation to include reputation
    struct Delegation {
        delegator: address,
        delegatee: address,
        category: field,
        amount: u64,
        reputation: u64,
    }

    // New struct for delegatee reputation
    struct DelegateeReputation {
        address: address,
        category: field,
        reputation_score: u64,
        proposals_supported: u32,
        proposals_succeeded: u32,
    }
   // Modified struct for staking to include last claim time
    struct Stake {
        owner: address,
        amount: u64,
        start_time: u32,
        duration: u32,
        last_claim_time: u32,
    }

    // New struct for slashing proposals
    struct SlashingProposal {
        target: address,
        category: field,
        amount: i64,
        reason: field,
    }


    mapping stakes: address => Stake;




    transition stake(token: governance_token.aleo/Token) -> bool {
        let current_stake: Stake = Mapping::get_or_use(stakes, self.caller, Stake {
            user: self.caller,
            amount: 0u64,
            start_time: block.height,
        });

        let new_stake: Stake = Stake {
            user: self.caller,
            amount: current_stake.amount + token.amount,
            start_time: block.height,
        };

        Mapping::set(stakes, self.caller, new_stake);

        return true;
    }

// New transition to unstake tokens
    transition unstake_tokens() -> GovernanceToken {
        let stake: Stake = Mapping::get(stakes, self.caller);
        assert(block.height >= stake.start_time + stake.duration);

        let bonus: u64 = calculate_staking_bonus(stake, block.height);
        let total_amount: u64 = stake.amount + bonus;

        // Remove the stake
        Mapping::remove(stakes, self.caller);

        // In a real implementation, you'd need to handle token unlocking here
        return GovernanceToken {
            owner: self.caller,
            amount: total_amount,
            // ... other fields
        };
    }


    // Modified function to calculate staking bonus with a more nuanced approach
    function calculate_staking_bonus(stake: Stake, current_time: u32) -> u64 {
        let time_staked: u32 = current_time - stake.last_claim_time;
        let bonus_rate: u64 = MAX_STAKING_BONUS_RATE * (1u64 - 2u64.pow(-time_staked / STAKING_BONUS_HALF_TIME));
        return (stake.amount * bonus_rate) / 100u64;
    }

    // Modified transition to stake tokens
    transition stake_tokens(amount: u64, duration: u32, token: GovernanceToken) -> bool {
        assert(token.amount >= amount);

        let new_stake: Stake = Stake {
            owner: token.owner,
            amount: amount,
            start_time: block.height,
            duration: duration,
            last_claim_time: block.height,
        };

        Mapping::set(stakes, token.owner, new_stake);

        // In a real implementation, you'd need to handle token locking here
        // token.amount -= amount;

        return true;
    }

    // New transition to claim staking rewards
    transition claim_staking_rewards() -> u64 {
        let mut stake: Stake = Mapping::get(stakes, self.caller);
        let bonus: u64 = calculate_staking_bonus(stake, block.height);

        // Update last claim time
        stake.last_claim_time = block.height;
        Mapping::set(stakes, self.caller, stake);

        // In a real implementation, you'd need to handle minting or transferring the bonus tokens here
        return bonus;
    }

    // Other staking-related functions...
}


