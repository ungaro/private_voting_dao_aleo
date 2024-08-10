    import privadao_core_v1.aleo;
    import privadao_governance_token_v1.aleo;
    import privadao_proposal_management_v1.aleo;

// The 'privadao_voting_system_v1' program.
program privadao_voting_system_v1.aleo {

    struct Vote {
        proposal_id: field,
        voter: address,
        vote: u64,
        weight: u64,
    }

    mapping votes: (field, address) => Vote;

    transition cast_vote(
        dao_id: field,
        proposal_id: field,
        vote: u64,
        token: governance_token.aleo/Token
    ) -> bool {
        let proposal: proposal_management.aleo/Proposal = proposal_management.aleo/get_proposal(proposal_id);
        assert(block.height >= proposal.start_time && block.height <= proposal.end_time);

        let weight: u64 = token.amount; // In reality, this would be more complex

        let new_vote: Vote = Vote {
            proposal_id: proposal_id,
            voter: self.caller,
            vote: vote,
            weight: weight,
        };

        Mapping::set(votes, (proposal_id, self.caller), new_vote);

        return true;
    }



    transition cast_vote(ballot_id: field, choices: [u8; 10], token: GovernanceToken) -> bool {
        let ballot: Ballot = Mapping::get(ballots, ballot_id);
        let vote_type: VoteType = Mapping::get(vote_types, ballot_id);

        // Check if voting period is active
        let status: ProposalStatus = Mapping::get(proposal_status, ballot_id);
        assert(block.height >= status.voting_start && block.height <= status.voting_end);

        // Validate vote based on vote type
        assert(validate_vote(vote_type, choices));

        // Calculate voting power
        let voting_power: u64 = calculate_voting_power(token.owner, token.amount);

        // Create and store the vote
        let new_vote: Vote = Vote {
            voter: token.owner,
            choices: choices,
            weight: voting_power,
        };

        let current_votes: [Vote; 1000] = Mapping::get_or_use(votes, ballot_id, [Vote { voter: self.caller, choices: [0u8; 10], weight: 0u64 }; 1000]);
        // Find the first empty slot and add the new vote
        for i: u16 in 0u16..1000u16 {
            if current_votes[i].weight == 0u64 {
                current_votes[i] = new_vote;
                break;
            }
        }
        Mapping::set(votes, ballot_id, current_votes);

        // Update vote results
        update_vote_results(ballot_id, choices, voting_power);

        return true;
    }

    // Function to validate votes based on vote type
    function validate_vote(vote_type: VoteType, choices: [u8; 10]) -> bool {
        if vote_type.single_choice {
            // Ensure only one non-zero choice
            let mut count: u8 = 0u8;
            for i: u8 in 0u8..10u8 {
                if choices[i] != 0u8 {
                    count += 1u8;
                }
            }
            return count == 1u8;
        } else if vote_type.multiple_choice {
            // Ensure number of choices doesn't exceed options_count
            let mut count: u8 = 0u8;
            for i: u8 in 0u8..10u8 {
                if choices[i] != 0u8 {
                    count += 1u8;
                }
            }
            return count <= vote_type.options_count;
        } else if vote_type.ranked_choice {
            // Ensure ranks are unique and don't exceed options_count
            let mut used_ranks: [bool; 10] = [false; 10];
            for i: u8 in 0u8..vote_type.options_count {
                if choices[i] != 0u8 && choices[i] <= vote_type.options_count {
                    if used_ranks[choices[i] - 1u8] {
                        return false;
                    }
                    used_ranks[choices[i] - 1u8] = true;
                }
            }
            return true;
        }
        return false;
    }

    function update_vote_results(ballot_id: field, choices: [u8; 10], weight: u64) {
        let mut results: [u64; 10] = Mapping::get_or_use(vote_results, ballot_id, [0u64; 10]);
        for i: u8 in 0u8..10u8 {
            if choices[i] != 0u8 {
                results[i] += weight;
            }
        }
        Mapping::set(vote_results, ballot_id, results);
    }



    // Modified transition to cast a vote with sophisticated voting power calculation
    transition cast_vote(proposal_id: field, vote: u64, token: GovernanceToken) -> field {
        let proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        // Ensure proposal is in voting phase and not vetoed
        assert(proposal.status == 1u8);
        assert(proposal.veto_count < proposal.veto_threshold);
        assert(block.height >= proposal.discussion_end_time && block.height < proposal.voting_end_time);

        // Calculate voting power
        let voting_power: u64 = calculate_voting_power(token);

        // ... (rest of the voting logic remains the same)
    }

    // New function to calculate voting power based on token amount and lock-up duration
    function calculate_voting_power(token: GovernanceToken) -> u64 {
        let base_power: u64 = calculate_quadratic_voting_power(token.amount);
        let lock_up_bonus: u64 = (token.locked_until - block.height) / 100u32; // Bonus for every 100 blocks of lock-up
        return base_power + (base_power * lock_up_bonus) / 100u64; // Max 100% bonus
    }


    // Other voting-related functions...
}



