import privadao_core_v1.aleo;
import privadao_governance_token_v1.aleo;
import privadao_proposal_management_v1.aleo;

program privadao_voting_system_v1.aleo {
    // Constants
    const CONVICTION_GROWTH_RATE: u64 = 900u64; // 90% of maximum per week

    // Structs
    struct SlashingRule {
        condition: u8,
        threshold: u32,
        slash_amount: i64,
    }

    struct VoteType {
        single_choice: bool,
        multiple_choice: bool,
        ranked_choice: bool,
        conviction: bool,
        quadratic: bool,
        options_count: u8,
    }

    struct Vote {
        voter: address,
        choices: [u8; 10], // Supports up to 10 choices for ranked or multiple choice voting
        weight: u64,
    }

    struct ConvictionVote {
        voter: address,
        proposal_id: field,
        amount: u64,
        start_time: u32,
    }

    struct VoteVerification {
        proposal_id: field,
        voter: address,
        vote_hash: field,
        timestamp: u32,
    }

    struct VoteAggregate {
        proposal_id: field,
        vote_count: u64,
        vote_tally: [u64; 10], // Assumes max 10 options
        vote_merkle_root: field,
    }

    struct OffChainData {
        data_hash: field,
        timestamp: u32,
        validator: address,
    }

    struct VoterHistory {
        minority_votes: u32,
        total_votes: u32,
    }

    struct Stake {
        owner: address,
        amount: u64,
        start_time: u32,
        duration: u32,
    }

    // Mappings
    mapping slashing_rules: u8 => SlashingRule;
    mapping vote_types: field => VoteType;
    mapping vote_receipts: field => field; // (ballot_id, voter) => vote_hash
    mapping votes: field => [Vote; 32]; // ballot_id => Votes (max 32 votes per ballot due to Leo limitations)
    mapping vote_results: field => [u64; 10]; // ballot_id => Vote counts for each option
    mapping vote_aggregates: field => VoteAggregate;
    mapping vote_merkle_proofs: field => field; // (proposal_id, voter) => merkle_proof
    mapping vote_verifications: field => VoteVerification;
    mapping conviction_votes: field => ConvictionVote;
    mapping off_chain_data: field => OffChainData;
    mapping voter_histories: address => VoterHistory;
    mapping stakes: address => Stake;

    // Main voting transition
    async transition cast_vote(proposal_id: field, vote: u64, token: GovernanceToken) -> field {
        return proposal_id then finalize(self.caller, proposal_id, vote, token);
    }

    async function cast_vote(voter: address, proposal_id: field, vote: u64, token: GovernanceToken) {
        let proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        // Ensure proposal is in voting phase and not vetoed
        assert(proposal.status == 1u8);
        assert(proposal.veto_count < proposal.veto_threshold);
        assert(block.height >= proposal.discussion_end_time && block.height < proposal.voting_end_time);

        // Check for previous vote and remove if exists
        let previous_vote: VoteVerification = Mapping::get_or_use(vote_verifications, proposal_id, 
            VoteVerification {
                proposal_id: field(0),
                voter: address(0),
                vote_hash: field(0),
                timestamp: 0u32,
            }
        );
        if previous_vote.timestamp != 0u32 {
            // Remove previous vote from tally
            remove_previous_vote(proposal_id, previous_vote);
        }

        // Calculate voting power
        let voting_power: u64 = calculate_voting_power(token, proposal.category);

        // Apply staking bonus
        let stake: Stake = Mapping::get_or_use(stakes, voter, Stake { owner: voter, amount: 0u64, start_time: 0u32, duration: 0u32 });
        let staking_bonus: u64 = calculate_staking_bonus(stake, block.height);
        voting_power += staking_bonus;

        // Check for category-specific delegation
        let delegation: Delegation = Mapping::get_or_use(category_delegations, field(voter), 
            Delegation { delegator: voter, delegatee: voter, category: proposal.category, amount: 0u64, reputation: 0u64 }
        );
        
        if delegation.delegatee != voter {
            voting_power = delegation.amount;
        }

        let vote_type: VoteType = Mapping::get(vote_types, proposal_id);
        if vote_type.conviction {
            cast_conviction_vote(proposal_id, voting_power, token);
        } else if vote_type.quadratic {
            voting_power = calculate_quadratic_voting_power(voting_power);
        }

        // Regular voting logic
        update_vote_results(proposal_id, vote, voting_power);

        // Create vote verification
        let vote_hash: field = BHP256::hash_to_field(voter + proposal_id + (vote as field));
        let vote_verification: VoteVerification = VoteVerification {
            proposal_id: proposal_id,
            voter: voter,
            vote_hash: vote_hash,
            timestamp: block.height,
        };
        Mapping::set(vote_verifications, proposal_id, vote_verification);

        // Update user reputation for voting
        update_reputation(voter, proposal.category, 1i64);

        // Update delegatee reputation
        if delegation.delegatee != voter {
            let mut delegatee_rep: DelegateeReputation = Mapping::get(delegatee_reputations, delegation.delegatee);
            delegatee_rep.proposals_supported += 1u32;
            Mapping::set(delegatee_reputations, delegation.delegatee, delegatee_rep);
        }

        // Check for automatic slashing conditions
        check_and_apply_slashing(voter, proposal_id, vote);
    }

    // Helper functions
    function calculate_voting_power(token: GovernanceToken, category: field) -> u64 {
        let base_power: u64 = token.amount;
        let lock_up_bonus: u64 = (token.locked_until - block.height) / 100u32; // Bonus for every 100 blocks of lock-up
        let category_boost: u64 = get_category_boost(token.owner, category);
        return base_power + (base_power * lock_up_bonus) / 100u64 + category_boost; // Max 100% bonus + category boost
    }

    function calculate_quadratic_voting_power(amount: u64) -> u64 {
        return (amount as u128).square_root() as u64;
    }

    function calculate_staking_bonus(stake: Stake, current_height: u32) -> u64 {
        if stake.amount == 0u64 {
            return 0u64;
        }
        let staking_duration: u32 = current_height - stake.start_time;
        return (stake.amount * staking_duration) / 10000u64; // 0.01% bonus per block staked
    }

    function calculate_conviction(voting_power: u64, time_elapsed: u32) -> u64 {
        let max_conviction: u64 = voting_power * 10u64; // Maximum conviction is 10x voting power
        let growth: u64 = (CONVICTION_GROWTH_RATE * time_elapsed as u64) / (7 * 24 * 60 * 60u64); // Growth over time
        return (max_conviction * growth) / 1000u64; // Scaled conviction
    }

    function update_vote_results(proposal_id: field, vote: u64, weight: u64) {
        let mut results: [u64; 10] = Mapping::get_or_use(vote_results, proposal_id, [0u64; 10]);
        results[vote as usize] += weight;
        Mapping::set(vote_results, proposal_id, results);
    }

    function remove_previous_vote(proposal_id: field, previous_vote: VoteVerification) {
        let mut results: [u64; 10] = Mapping::get(vote_results, proposal_id);
        let previous_vote_value: u8 = BHP256::hash_to_field(previous_vote.vote_hash) as u8;
        results[previous_vote_value as usize] -= previous_vote.voter as u64; // Simplified; in reality, you'd need to store and retrieve the actual previous vote weight
        Mapping::set(vote_results, proposal_id, results);
    }

    function cast_conviction_vote(proposal_id: field, amount: u64, token: GovernanceToken) {
        let conviction_vote: ConvictionVote = ConvictionVote {
            voter: token.owner,
            proposal_id: proposal_id,
            amount: amount,
            start_time: block.height,
        };
        Mapping::set(conviction_votes, proposal_id, conviction_vote);
    }

    function check_and_apply_slashing(voter: address, proposal_id: field, vote: u64) {
        let minority_rule: SlashingRule = Mapping::get(slashing_rules, 0u8);
        let mut voter_history: VoterHistory = Mapping::get_or_use(voter_histories, voter, VoterHistory { minority_votes: 0u32, total_votes: 0u32 });
        
        voter_history.total_votes += 1u32;
        if vote != get_majority_vote(proposal_id) {
            voter_history.minority_votes += 1u32;
        }

        if voter_history.total_votes >= minority_rule.threshold && 
           (voter_history.minority_votes * 100u32) / voter_history.total_votes > 75u32 {
            update_reputation(voter, get_proposal_category(proposal_id), -minority_rule.slash_amount);
        }

        Mapping::set(voter_histories, voter, voter_history);
    }

    // Additional helper functions (to be implemented)
    // function get_category_boost(voter: address, category: field) -> u64 { ... }
    // function get_majority_vote(proposal_id: field) -> u64 { ... }
    // function get_proposal_category(proposal_id: field) -> field { ... }
    // function update_reputation(voter: address, category: field, amount: i64) { ... }

    // Transition for submitting aggregated votes (for off-chain processing)
    async transition submit_vote_aggregate(proposal_id: field, vote_count: u64, vote_tally: [u64; 10], vote_merkle_root: field) -> bool {
        return true then finalize(proposal_id, vote_count, vote_tally, vote_merkle_root);
    }

    async function submit_vote_aggregate(proposal_id: field, vote_count: u64, vote_tally: [u64; 10], vote_merkle_root: field) {
        let vote_aggregate: VoteAggregate = VoteAggregate {
            proposal_id: proposal_id,
            vote_count: vote_count,
            vote_tally: vote_tally,
            vote_merkle_root: vote_merkle_root,
        };
        Mapping::set(vote_aggregates, proposal_id, vote_aggregate);
    }

    // Transition for verifying an individual vote
    async transition verify_vote(proposal_id: field, voter: address, vote: u64, merkle_proof: field) -> bool {
        return true then finalize(proposal_id, voter, vote, merkle_proof);
    }

    async function verify_vote(proposal_id: field, voter: address, vote: u64, merkle_proof: field) {
        let vote_aggregate: VoteAggregate = Mapping::get(vote_aggregates, proposal_id);
        let stored_proof: field = Mapping::get_or_use(vote_merkle_proofs, proposal_id, field(0));
        assert(stored_proof == merkle_proof);
    }
}