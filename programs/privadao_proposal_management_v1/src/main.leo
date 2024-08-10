import core_dao.aleo;
import governance_token.aleo;

// The 'privadao_proposal_management_v1' program.
program privadao_proposal_management_v1.aleo {


    struct Proposal {
        id: field,
        creator: address,
        description: field,
        proposal_type: u8,
        start_time: u32,
        end_time: u32,
        status: u8,
    }

    // Struct for a proposal
    struct Proposal {
        id: field,
        creator: address,
        description: field,
        vote_type: VoteType,
        options_count: u8,
        treasury_action: TreasuryAction,
        start_time: u32,
        end_time: u32,
        executed: bool,
    }


    // Modified struct for proposals to include amendment information
    struct Proposal {
        id: field,
        creator: address,
        description: field,
        proposal_type: u8,
        vote_type: VoteType,
        options_count: u8,
        treasury_action: TreasuryAction,
        status: u8,
        discussion_end_time: u32,
        voting_end_time: u32,
        grace_period_end_time: u32,
        required_sponsorship: u64,
        total_sponsorship: u64,
        veto_count: u64,
        veto_threshold: u64,
        amendment_count: u32,
        parent_proposal: field, // field(0) if it's not an amendment
    }


    mapping proposals: field => Proposal;

    transition create_proposal(
        dao_id: field,
        description: field,
        proposal_type: u8,
        duration: u32
    ) -> field {
        // Verify caller has enough tokens/reputation (would call reputation system here)

        let proposal_id: field = BHP256::hash_to_field(description);
        
        let new_proposal: Proposal = Proposal {
            id: proposal_id,
            creator: self.caller,
            description: description,
            proposal_type: proposal_type,
            start_time: block.height,
            end_time: block.height + duration,
            status: 0u8, // Active
        };

        Mapping::set(proposals, proposal_id, new_proposal);

        return proposal_id;
    }


    // Transition to create a new proposal
    transition create_proposal(
        description: field,
        vote_type: VoteType,
        options_count: u8,
        treasury_action: TreasuryAction,
        duration: u32
    ) -> field {
        // Ensure the creator has enough reputation to create a proposal
        let creator_reputation: u64 = Mapping::get_or_use(user_reputation, self.caller, 0u64);
        assert(creator_reputation >= 100u64); // Arbitrary threshold, can be adjusted

        let proposal_id: field = BHP256::hash_to_field(description);
        
        let new_proposal: Proposal = Proposal {
            id: proposal_id,
            creator: self.caller,
            description: description,
            vote_type: vote_type,
            options_count: options_count,
            treasury_action: treasury_action,
            start_time: block.height,
            end_time: block.height + duration,
            executed: false,
        };

        Mapping::set(proposals, proposal_id, new_proposal);

        // Initialize vote count
        Mapping::set(vote_counts, proposal_id, 0field);

        return proposal_id;
    }




   // Transition to execute a proposal based on voting results
    transition execute_proposal(proposal_id: field) -> bool {
        let status: ProposalStatus = Mapping::get(proposal_status, proposal_id);
        assert(block.height > status.voting_end && !status.executed);

        let vote_type: VoteType = Mapping::get(vote_types, proposal_id);
        let results: [u64; 10] = Mapping::get(vote_results, proposal_id);

        let winning_option: u8 = determine_winning_option(vote_type, results);

        // Execute the proposal action based on the winning option
        // This is a placeholder - actual execution would depend on the proposal type
        let execution_success: bool = execute_proposal_action(proposal_id, winning_option);

        if execution_success {
            status.executed = true;
            Mapping::set(proposal_status, proposal_id, status);
        }

        return execution_success;
    }



    // Transition to execute a proposal
    transition execute_proposal(proposal_id: field) -> bool {
        let mut proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        // Ensure voting period has ended and proposal hasn't been executed
        assert(block.height > proposal.end_time && !proposal.executed);

        // In a real implementation, we would decrypt and tally the votes here
        // For now, we'll assume the proposal passed

        // Execute treasury action
        if proposal.treasury_action.action_type == 1u8 { // Transfer
            let current_balance: u64 = Mapping::get_or_use(treasury, proposal.treasury_action.asset, 0u64);
            assert(current_balance >= proposal.treasury_action.amount);
            
            Mapping::set(treasury, proposal.treasury_action.asset, current_balance - proposal.treasury_action.amount);
            
            let recipient_balance: u64 = Mapping::get_or_use(governance_token_balance, proposal.treasury_action.recipient, 0u64);
            Mapping::set(governance_token_balance, proposal.treasury_action.recipient, recipient_balance + proposal.treasury_action.amount);
        } else if proposal.treasury_action.action_type == 2u8 { // Mint
            let current_supply: u64 = Mapping::get_or_use(treasury, proposal.treasury_action.asset, 0u64);
            Mapping::set(treasury, proposal.treasury_action.asset, current_supply + proposal.treasury_action.amount);
        } else if proposal.treasury_action.action_type == 3u8 { // Burn
            let current_supply: u64 = Mapping::get_or_use(treasury, proposal.treasury_action.asset, 0u64);
            assert(current_supply >= proposal.treasury_action.amount);
            Mapping::set(treasury, proposal.treasury_action.asset, current_supply - proposal.treasury_action.amount);
        }

        // Mark proposal as executed
        proposal.executed = true;
        Mapping::set(proposals, proposal_id, proposal);

        // Update reputation of proposal creator
        let creator_reputation: u64 = Mapping::get_or_use(user_reputation, proposal.creator, 0u64);
        Mapping::set(user_reputation, proposal.creator, creator_reputation + 10u64);

        return true;
    }



    // Function to determine the winning option based on vote type and results
    function determine_winning_option(vote_type: VoteType, results: [u64; 10]) -> u8 {
        if vote_type.single_choice || vote_type.multiple_choice {
            // Find the option with the most votes
            let mut max_votes: u64 = 0u64;
            let mut winning_option: u8 = 0u8;
            for i: u8 in 0u8..vote_type.options_count {
                if results[i] > max_votes {
                    max_votes = results[i];
                    winning_option = i + 1u8;
                }
            }
            return winning_option;
        } else if vote_type.ranked_choice {
            // Implement Instant Runoff Voting (IRV) for ranked choice
            // This is a simplified version and might need to be more sophisticated in practice
            let mut eliminated: [bool; 10] = [false; 10];
            loop {
                let mut min_votes: u64 = u64::max();
                let mut max_votes: u64 = 0u64;
                let mut min_option: u8 = 0u8;
                let mut max_option: u8 = 0u8;

                for i: u8 in 0u8..vote_type.options_count {
                    if !eliminated[i] {
                        if results[i] < min_votes {
                            min_votes = results[i];
                            min_option = i + 1u8;
                        }
                        if results[i] > max_votes {
                            max_votes = results[i];
                            max_option = i + 1u8;
                        }
                    }
                }

                if max_votes > (results[0] + results[1] + results[2] + results[3] + results[4] + results[5] + results[6] + results[7] + results[8] + results[9]) / 2u64 {
                    return max_option;
                }

                eliminated[min_option - 1u8] = true;
                // Redistribute votes from eliminated option
                // (In practice, this would require iterating through all votes)
            }
        }
        return 0u8;
    }

    // Placeholder function for executing proposal action
    function execute_proposal_action(proposal_id: field, winning_option: u8) -> bool {
        // Implementation would depend on the type of actions the DAO can take
        // This could involve treasury management, parameter changes, etc.
        return true;
    }

    // Transition for advanced delegation
    transition delegate_votes(delegatee: address, percentage: u8) -> bool {
        assert(percentage <= 100u8);

        let delegation_info: DelegationInfo = DelegationInfo {
            delegatee: delegatee,
            percentage: percentage,
        };

        Mapping::set(delegations, self.caller, delegation_info);

        return true;
    }



    // Modified transition to create a new proposal with sponsorship requirement
    transition create_proposal(
        description: field,
        proposal_type: u8,
        vote_type: VoteType,
        options_count: u8,
        treasury_action: TreasuryAction,
        discussion_duration: u32,
        voting_duration: u32,
        grace_period_duration: u32,
        required_sponsorship: u64,
        veto_threshold: u64
    ) -> field {
        // ... (previous implementation remains largely the same)

        let proposal_id: field = BHP256::hash_to_field(description);
        
        let new_proposal: Proposal = Proposal {
            id: proposal_id,
            creator: self.caller,
            description: description,
            proposal_type: proposal_type,
            vote_type: vote_type,
            options_count: options_count,
            treasury_action: treasury_action,
            status: 0u8, // Start in discussion phase
            discussion_end_time: block.height + discussion_duration,
            voting_end_time: block.height + discussion_duration + voting_duration,
            grace_period_end_time: block.height + discussion_duration + voting_duration + grace_period_duration,
            required_sponsorship: required_sponsorship,
            total_sponsorship: 0u64,
            veto_count: 0u64,
            veto_threshold: veto_threshold,
        };

        Mapping::set(proposals, proposal_id, new_proposal);

        // Initialize vote count with encrypted zero
        let zero_vote: HomomorphicCiphertext = encrypt_vote(0u64, generate_encryption_params());
        Mapping::set(vote_counts, proposal_id, zero_vote);

        return proposal_id;
    }

    // New transition to sponsor a proposal
    transition sponsor_proposal(proposal_id: field, amount: u64, token: GovernanceToken) -> bool {
        let mut proposal: Proposal = Mapping::get(proposals, proposal_id);
        assert(proposal.status == 0u8); // Only sponsor during discussion phase

        let sponsorship: Sponsorship = Sponsorship {
            sponsor: token.owner,
            amount: amount,
        };

        Mapping::set(proposal_sponsorships, proposal_id, sponsorship);
        proposal.total_sponsorship += amount;
        Mapping::set(proposals, proposal_id, proposal);

        // Update reputation of sponsor
        update_reputation(token.owner, (amount / 100u64) as i64);

        return true;
    }

    // New transition to veto a proposal
    transition veto_proposal(proposal_id: field, token: GovernanceToken) -> bool {
        let mut proposal: Proposal = Mapping::get(proposals, proposal_id);
        assert(proposal.status < 3u8); // Can veto before execution

        let has_vetoed: bool = Mapping::get_or_use(user_vetos, (proposal_id, token.owner), false);
        assert(!has_vetoed); // User hasn't already vetoed

        proposal.veto_count += calculate_voting_power(token);
        Mapping::set(proposals, proposal_id, proposal);
        Mapping::set(user_vetos, (proposal_id, token.owner), true);

        if proposal.veto_count >= proposal.veto_threshold {
            proposal.status = 4u8; // Mark as expired/canceled
            Mapping::set(proposals, proposal_id, proposal);
        }

        return true;
    }


    // Modified transition to execute a proposal
    transition execute_proposal(proposal_id: field) -> bool {
        let mut proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        // Ensure proposal is in grace period, hasn't been executed, and not vetoed
        assert(proposal.status == 2u8 && block.height >= proposal.grace_period_end_time);
        assert(proposal.veto_count < proposal.veto_threshold);

        let encrypted_tally: HomomorphicCiphertext = Mapping::get(vote_counts, proposal_id);
        
        // Assume the proposal passed if c2 != 0 (in practice, this would involve proper decryption and threshold checking)
        if encrypted_tally.c2 != group::ZERO {
            // Execute based on proposal type
            if proposal.proposal_type == 0u8 {
                execute_treasury_action(proposal.treasury_action);
            } else if proposal.proposal_type == 1u8 {
                execute_parameter_change(proposal_id);
            } else if proposal.proposal_type == 2u8 {
                execute_contract_upgrade(proposal_id);
            }

            // Mark proposal as executed
            proposal.status = 3u8;
            Mapping::set(proposals, proposal_id, proposal);

            // Update reputation of proposal creator
            update_reputation(proposal.creator, 10i64);

            return true;
        }

        // If the proposal didn't pass, mark it as expired
        proposal.status = 4u8;
        Mapping::set(proposals, proposal_id, proposal);
        return false;
    }


      // Modified transition to create a new proposal
    transition create_proposal(
        description: field,
        proposal_type: u8,
        vote_type: VoteType,
        options_count: u8,
        treasury_action: TreasuryAction,
        discussion_duration: u32,
        voting_duration: u32,
        grace_period_duration: u32,
        required_sponsorship: u64,
        veto_threshold: u64
    ) -> field {
        // ... (previous implementation remains largely the same)

        let proposal_id: field = BHP256::hash_to_field(description);
        
        let new_proposal: Proposal = Proposal {
            id: proposal_id,
            creator: self.caller,
            description: description,
            proposal_type: proposal_type,
            vote_type: vote_type,
            options_count: options_count,
            treasury_action: treasury_action,
            status: 0u8, // Start in discussion phase
            discussion_end_time: block.height + discussion_duration,
            voting_end_time: block.height + discussion_duration + voting_duration,
            grace_period_end_time: block.height + discussion_duration + voting_duration + grace_period_duration,
            required_sponsorship: required_sponsorship,
            total_sponsorship: 0u64,
            veto_count: 0u64,
            veto_threshold: veto_threshold,
            amendment_count: 0u32,
            parent_proposal: field(0),
        };

        Mapping::set(proposals, proposal_id, new_proposal);

        // Update user reputation for creating a proposal
        let mut reputation: Reputation = Mapping::get_or_use(user_reputation, self.caller, Reputation { score: 0i64, proposal_count: 0u32, vote_count: 0u32, successful_proposals: 0u32 });
        reputation.proposal_count += 1u32;
        Mapping::set(user_reputation, self.caller, reputation);

        return proposal_id;
    }

    // New transition to amend a proposal
    transition amend_proposal(
        parent_proposal_id: field,
        description: field,
        treasury_action: TreasuryAction
    ) -> field {
        let parent_proposal: Proposal = Mapping::get(proposals, parent_proposal_id);
        assert(parent_proposal.status == 0u8); // Can only amend during discussion phase
        assert(parent_proposal.creator == self.caller); // Only creator can amend

        let amendment_id: field = BHP256::hash_to_field(description);
        
        let amended_proposal: Proposal = Proposal {
            id: amendment_id,
            creator: self.caller,
            description: description,
            proposal_type: parent_proposal.proposal_type,
            vote_type: parent_proposal.vote_type,
            options_count: parent_proposal.options_count,
            treasury_action: treasury_action,
            status: 0u8,
            discussion_end_time: parent_proposal.discussion_end_time,
            voting_end_time: parent_proposal.voting_end_time,
            grace_period_end_time: parent_proposal.grace_period_end_time,
            required_sponsorship: parent_proposal.required_sponsorship,
            total_sponsorship: parent_proposal.total_sponsorship,
            veto_count: 0u64,
            veto_threshold: parent_proposal.veto_threshold,
            amendment_count: parent_proposal.amendment_count + 1u32,
            parent_proposal: parent_proposal_id,
        };

        Mapping::set(proposals, amendment_id, amended_proposal);

        // Update the parent proposal's amendment count
        parent_proposal.amendment_count += 1u32;
        Mapping::set(proposals, parent_proposal_id, parent_proposal);

        return amendment_id;
    }



    // Modified transition to execute a proposal
    transition execute_proposal(proposal_id: field) -> bool {
        let mut proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        // Ensure proposal is in grace period, hasn't been executed, and not vetoed
        assert(proposal.status == 2u8 && block.height >= proposal.grace_period_end_time);
        assert(proposal.veto_count < proposal.veto_threshold);

        let vote_aggregate: VoteAggregate = Mapping::get(vote_aggregates, proposal_id);
        
        // Check if the proposal passed (simple majority for this example)
        let total_votes: u64 = vote_aggregate.vote_tally[0] + vote_aggregate.vote_tally[1];
        let passed: bool = vote_aggregate.vote_tally[0] > total_votes / 2u64;

        if passed {
            // Execute based on proposal type
            if proposal.proposal_type == 0u8 {
                execute_treasury_action(proposal.treasury_action);
            } else if proposal.proposal_type == 1u8 {
                execute_parameter_change(proposal_id);
            } else if proposal.proposal_type == 2u8 {
                execute_contract_upgrade(proposal_id);
            }

            // Mark proposal as executed
            proposal.status = 3u8;
            Mapping::set(proposals, proposal_id, proposal);

            // Update reputation of proposal creator
            let mut creator_reputation: Reputation = Mapping::get(user_reputation, proposal.creator);
            creator_reputation.score += 100i64;
            creator_reputation.successful_proposals += 1u32;
            Mapping::set(user_reputation, proposal.creator, creator_reputation);

            return true;
        }

        // If the proposal didn't pass, mark it as expired
        proposal.status = 4u8;
        Mapping::set(proposals, proposal_id, proposal);

        // Update reputation of proposal creator for failed proposal
        let mut creator_reputation: Reputation = Mapping::get(user_reputation, proposal.creator);
        creator_reputation.score -= 50i64;
        Mapping::set(user_reputation, proposal.creator, creator_reputation);

        return false;
    }

    // Existing helper functions...
}







