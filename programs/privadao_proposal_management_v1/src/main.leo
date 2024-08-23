

program privadao_proposal_management_v1.aleo {
    
    // @note Constants
    // Constants
    //7u8 * 24u8 * 60u8 * 60u8; // 1 week in seconds
    const MIN_PROPOSAL_DURATION: u32 = 604800u32; // 1 week in seconds
    //30u8 * 24u8 * 60u8 * 60u8; // 30 days in seconds
    const MAX_PROPOSAL_DURATION: u32 = 2592000u32; // 30 days in seconds
    const QUORUM_THRESHOLD: u64 = 100000000000u64; // 10% of total supply in base units
    const CONVICTION_GROWTH_RATE: u64 = 900u64; // 90% of maximum per week
    const WITHDRAW_DELAY: u32 = 360u32;
    const CACHE_BATCH_NUM: u32 = 10u32;
    const ZERO_ADDRESS: address = aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc;

    // @note Records
    record Token {
        owner: address,
        amount: u64,
    }

    record GovernanceToken {
        owner: address,
        amount: u64,
        locked_until: u64,
    }

    // @note Structs
    struct Vote {
        proposal_id: field,
        voter: address,
        vote: u64,
        weight: u64,
    }

    struct VoteAggregate {
        proposal_id: field,
        vote_count: u64,
        vote_tally: [u64; 10], // Assumes max 10 options
        vote_merkle_root: field,
    }

    struct VoteVerification {
        proposal_id: field,
        voter: address,
        vote_hash: field,
        timestamp: u32,
    }


    struct VoterHistory {
        minority_votes: u32,
        total_votes: u32,
    }

    // Structs
    struct GovernanceTier {
        proposal_types: [u8; 10],
        // Add other tier-specific properties
    }

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
        parent_proposal: field,
        tags: [field; 5],
        category: field,
        min_participation: u64,
        security_level: u8,
    }

    struct ProposalStatus {
        draft: bool,
        discussion_end: u32,
        voting_start: u32,
        voting_end: u32,
        executed: bool,
    }

    struct Comment {
        author: address,
        content: field,
        timestamp: u32,
    }

    struct Delegation {
        delegator: address,
        delegatee: address,
        category: field,
        amount: u64,
        reputation: u64,
    }

    struct DelegationKey{
        delegator: address,
        category: field,
    }


    struct VetoKey{
        proposal_id: field,
        token_owner: address,
    }

    struct Stake {
        token_owner: address,
        amount: u64,
        start_time: u32,
        duration: u32,
    }

    struct DelegationInfo {
        delegatee: address,
        percentage: u8,
    }

    struct SlashingRule {
        condition: u8,
        threshold: u32,
        slash_amount: i64,
    }

    struct SlashingProposal {
        target: address,
        category: field,
        amount: i64,
        reason: field,
    }

    struct DelegateeReputation {
        delegatee_address: address,
        category: field,
        reputation_score: u64,
        proposals_supported: u32,
        proposals_succeeded: u32,
        last_update_time: u32,
    }

    struct Reputation {
        score: i64,
        proposal_count: u32,
        vote_count: u32,
        successful_proposals: u32,
    }

    struct VoteType {
        single_choice: bool,
        multiple_choice: bool,
        ranked_choice: bool,
        conviction: bool,
        quadratic: bool,
        options_count: u8,
    }

    struct TreasuryAction {
        action_type: u8,
        asset: field,
        amount: u64,
        recipient: address,
    }

    struct Sponsorship {
        sponsor: address,
        amount: u64,
    }

    struct ConvictionVote {
        voter: address,
        proposal_id: field,
        amount: u64,
        start_time: u32,
    }

    struct Comments {
        comments: [Comment; 32],

    }

    struct Tags {
        tag1: field,
        tag2: field,
        tag3: field,
        tag4: field,
        tag5: field,

    }
    
    // Additional structs and mappings needed for these functions
    struct TreasuryBalance {
        asset: field,
        amount: u64,
    }

    struct DAO_Parameters {
        quorum_threshold: u64,
        voting_period: u32,
        grace_period: u32,
    }

    struct MultiSigProposal {
        proposal_id: field,
        approvals: u8,
        required_approvals: u8,
    }



    // Mappings
    mapping governance_tiers: u8 => GovernanceTier;
    mapping proposals: field => Proposal;
    mapping proposal_status: field => ProposalStatus;
    mapping user_vetos: field => bool;
    mapping conviction_votes: field => ConvictionVote;
    mapping category_delegations: field => Delegation;
    mapping proposal_sponsorships: field => Sponsorship;
    mapping delegations: address => DelegationInfo;
    mapping comment_content: field => Comment;
    mapping proposal_comments: field => Comment;
    mapping slashing_proposals: field => SlashingProposal;
    mapping user_reputation: address => Reputation;
    mapping vote_counts: field => u64;
    mapping vote_aggregates: field => VoteAggregate;
    mapping delegatee_reputations: address => DelegateeReputation;
    mapping contract_upgrade: field => field;
    mapping contract_upgrades: field => field;


    // Mappings
    mapping slashing_rules: u8 => SlashingRule;
    mapping vote_types: field => VoteType;
    mapping vote_receipts: field => field; // (ballot_id, voter) => vote_hash
    mapping votes: field => Vote; // ballot_id => Votes (max 32 votes per ballot due to Leo limitations)
    
    mapping vote_results: field => [u64; 10]; // ballot_id => Vote counts for each option
    mapping vote_merkle_proofs: field => field; // (proposal_id, voter) => merkle_proof
    mapping vote_verifications: field => VoteVerification;
    //mapping conviction_votes: field => ConvictionVote;
    //mapping off_chain_data: field => OffChainData;
    mapping voter_histories: address => VoterHistory;
    mapping stakes: address => Stake;


    // Additional mappings
    mapping treasury: field => TreasuryBalance;
    mapping dao_parameters: field => DAO_Parameters;
    mapping multisig_proposals: field => MultiSigProposal;
    mapping token_locks: address => u32;





    // @note Create Proposal
    async transition create_proposal(
        description: field,
        proposal_type: u8,
        vote_type: VoteType,
        options_count: u8,
        treasury_action: TreasuryAction,
        discussion_duration: u32,
        voting_duration: u32,
        grace_period_duration: u32,
        required_sponsorship: u64,
        veto_threshold: u64,
        tags: [field;5],
        category: field,
        security_level: u8
    ) -> Future {
        // Input validation
        assert(discussion_duration + voting_duration + grace_period_duration >= MIN_PROPOSAL_DURATION);
        assert(discussion_duration + voting_duration + grace_period_duration <= MAX_PROPOSAL_DURATION);
        assert(security_level <= 2u8);

        let proposal_id: field = BHP256::hash_to_field(description);
        
        let min_participation:u64 = QUORUM_THRESHOLD;

       if (security_level == 0u8) {
            min_participation = QUORUM_THRESHOLD;
        }else if security_level == 1u8 {
            min_participation = QUORUM_THRESHOLD * 2u64;
        }else if security_level == 2u8{
            min_participation = QUORUM_THRESHOLD * 3u64;
        }else{
            min_participation = QUORUM_THRESHOLD;

        }

        return finalize_create_proposal(self.caller, proposal_id, description, proposal_type, vote_type, options_count, treasury_action, discussion_duration, voting_duration, grace_period_duration, required_sponsorship, veto_threshold, tags, category, security_level, min_participation);
    }

    async function finalize_create_proposal(
        creator: address,
        proposal_id: field,
        description: field,
        proposal_type: u8,
        vote_type: VoteType,
        options_count: u8,
        treasury_action: TreasuryAction,
        discussion_duration: u32,
        voting_duration: u32,
        grace_period_duration: u32,
        required_sponsorship: u64,
        veto_threshold: u64,
        tags: [field; 5],
        category: field,
        security_level: u8,
        min_participation: u64
    ){
        let creator_rep: DelegateeReputation = Mapping::get_or_use(delegatee_reputations, creator, DelegateeReputation {
            delegatee_address: creator,
            category: category,
            reputation_score: 0u64,
            proposals_supported: 0u32,
            proposals_succeeded: 0u32,
            last_update_time: block.height,
        });
        let creator_tier: u8 = get_governance_tier(creator_rep.reputation_score);
        let tier_info: GovernanceTier = Mapping::get(governance_tiers, creator_tier);

        // Check if the creator has permission to create this type of proposal

        let new_proposal: Proposal = Proposal {
            id: proposal_id,
            creator: creator,
            description: description,
            proposal_type: proposal_type,
            vote_type: vote_type,
            options_count: options_count,
            treasury_action: treasury_action,
            status: 0u8,
            discussion_end_time: block.height + discussion_duration,
            voting_end_time: block.height + discussion_duration + voting_duration,
            grace_period_end_time: block.height + discussion_duration + voting_duration + grace_period_duration,
            required_sponsorship: required_sponsorship,
            total_sponsorship: 0u64,
            veto_count: 0u64,
            veto_threshold: veto_threshold,
            amendment_count: 0u32,
            parent_proposal: 0field,
            tags: tags,
            category: category,
            min_participation: min_participation,
            security_level: security_level,
        };


        Mapping::set(proposals, proposal_id, new_proposal);

        // Initialize vote count
        Mapping::set(vote_counts, proposal_id, 0u64);

        // Update user reputation for creating a proposal
        let  reputation: Reputation = Mapping::get_or_use(user_reputation, creator, Reputation { score: 0i64, proposal_count: 0u32, vote_count: 0u32, successful_proposals: 0u32 });
        let new_proposal_count:u32 = reputation.proposal_count+1u32;
        Mapping::set(user_reputation, creator, Reputation { score: reputation.score, proposal_count: new_proposal_count, vote_count: reputation.vote_count, successful_proposals: reputation.successful_proposals });
    }


    

    async transition amend_proposal(
        parent_proposal_id: field,
        description: field,
        treasury_action: TreasuryAction
    ) -> Future {
        return finalize_amend_proposal(self.caller, parent_proposal_id, description, treasury_action);
    }

    async function finalize_amend_proposal(
        caller: address,
        parent_proposal_id: field,
        description: field,
        treasury_action: TreasuryAction
    ) {
        let parent_proposal: Proposal = Mapping::get(proposals, parent_proposal_id);
        assert(parent_proposal.status == 0u8); // Can only amend during discussion phase
        assert(parent_proposal.creator == caller); // Only creator can amend

        let amendment_id: field = BHP256::hash_to_field(description);
        
        let amended_proposal: Proposal = Proposal {
            id: amendment_id,
            creator: caller,
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
            tags: parent_proposal.tags,
            category: parent_proposal.category,
            min_participation: parent_proposal.min_participation,
            security_level: parent_proposal.security_level,
        };

        Mapping::set(proposals, amendment_id, amended_proposal);

        // Update the parent proposal's amendment count
        parent_proposal =  Proposal {
            id: parent_proposal.id,
            creator: parent_proposal.creator,
            description: parent_proposal.description,
            proposal_type: parent_proposal.proposal_type,
            vote_type: parent_proposal.vote_type,
            options_count: parent_proposal.options_count,
            treasury_action: parent_proposal.treasury_action,
            status: parent_proposal.status,
            discussion_end_time: parent_proposal.discussion_end_time,
            voting_end_time: parent_proposal.voting_end_time,
            grace_period_end_time: parent_proposal.grace_period_end_time,
            required_sponsorship: parent_proposal.required_sponsorship,
            total_sponsorship: parent_proposal.total_sponsorship,
            veto_count: parent_proposal.veto_count,
            veto_threshold: parent_proposal.veto_threshold,
            amendment_count: parent_proposal.amendment_count + 1u32,
            parent_proposal: parent_proposal.parent_proposal,
            tags: parent_proposal.tags,
            category: parent_proposal.category,
            min_participation: parent_proposal.min_participation,
            security_level: parent_proposal.security_level,
        };

        Mapping::set(proposals, parent_proposal_id, parent_proposal);

    }

    // @note Sponsor Proposal
     async transition sponsor_proposal(proposal_id: field, amount: u64, token: GovernanceToken) -> Future {
        return finalize_sponsor_proposal(self.caller, proposal_id, amount, token.owner);
    }

    async function finalize_sponsor_proposal(
        caller: address,
        proposal_id: field,
        amount: u64,
        token_owner: address
    ) {
        let proposal: Proposal = Mapping::get(proposals, proposal_id);
        assert(proposal.status == 0u8); // Only sponsor during discussion phase

        let sponsorship: Sponsorship = Sponsorship {
            sponsor: token_owner,
            amount: amount,
        };

        Mapping::set(proposal_sponsorships, proposal_id, sponsorship);
        
        //proposal.total_sponsorship =  proposal.total_sponsorship  + amount;
        
 let proposal_sp_add:Proposal =  Proposal {
        id: proposal.id,
        creator: proposal.creator,
        description: proposal.description,
        proposal_type: proposal.proposal_type,
        vote_type: proposal.vote_type,
        options_count: proposal.options_count,
        treasury_action: proposal.treasury_action,
        status: proposal.status,
        discussion_end_time: proposal.discussion_end_time,
        voting_end_time: proposal.voting_end_time,
        grace_period_end_time: proposal.grace_period_end_time,
        required_sponsorship: proposal.required_sponsorship,
        total_sponsorship: proposal.total_sponsorship + amount,
        veto_count: proposal.veto_count,
        veto_threshold: proposal.veto_threshold,
        amendment_count: proposal.amendment_count,
        parent_proposal: proposal.parent_proposal,
        tags: proposal.tags,
        category: proposal.category,
        min_participation: proposal.min_participation,
        security_level: proposal.security_level,
    };



        Mapping::set(proposals, proposal_id, proposal_sp_add);

        // Update reputation of sponsor
        let  reputation: Reputation = Mapping::get_or_use(user_reputation, caller, Reputation { score: 0i64, proposal_count: 0u32, vote_count: 0u32, successful_proposals: 0u32 });
        
        let reputation_sponsor_proposal:Reputation = Reputation { score: reputation.score + (amount / 100u64) as i64, proposal_count: reputation.proposal_count, vote_count: reputation.vote_count, successful_proposals: reputation.successful_proposals };


        Mapping::set(user_reputation, caller, reputation_sponsor_proposal);

    }

    // @note Veto Proposal
    async transition veto_proposal(proposal_id: field, token: GovernanceToken) -> Future {
        return finalize_veto_proposal(self.caller, proposal_id, token.owner,token.amount,token.locked_until);
    }

    async function finalize_veto_proposal(
        caller: address,
        proposal_id: field,
        token_owner: address,
        token_amount: u64,
        token_locked_until: u64
    ) {
        let  proposal: Proposal = Mapping::get(proposals, proposal_id);
        assert(proposal.status < 3u8); // Can veto before execution

        let has_vetoed: bool = Mapping::get_or_use(user_vetos, BHP256::hash_to_field(VetoKey{proposal_id:proposal_id,token_owner:token_owner}), false);
        assert(!has_vetoed); // User hasn't already vetoed

        let key: field = BHP256::hash_to_field(VetoKey{proposal_id:proposal_id,token_owner:token_owner});
        Mapping::set(user_vetos, key, true);


        //proposal.veto_count += calculate_voting_power(token);


 let proposal_new:Proposal =  Proposal {
        id: proposal.id,
        creator:  proposal.creator,
        description:  proposal.description,
        proposal_type:  proposal.proposal_type,
        vote_type:  proposal.vote_type,
        options_count:  proposal.options_count,
        treasury_action:  proposal.treasury_action,
        status:  proposal.status,
        discussion_end_time:  proposal.discussion_end_time,
        voting_end_time:  proposal.voting_end_time,
        grace_period_end_time:  proposal.grace_period_end_time,
        required_sponsorship:  proposal.required_sponsorship,
        total_sponsorship:  proposal.total_sponsorship,
        veto_count:  proposal.veto_count + calculate_voting_power(token_amount,token_locked_until),
        veto_threshold:  proposal.veto_threshold,
        amendment_count:  proposal.amendment_count,
        parent_proposal:  proposal.parent_proposal,
        tags:  proposal.tags,
        category:  proposal.category,
        min_participation:  proposal.min_participation,
        security_level: proposal.security_level,
    };






        Mapping::set(proposals, proposal_id, proposal_new);
        //Mapping::set(user_vetos, (proposal_id, token.owner), true);

        if proposal.veto_count >= proposal.veto_threshold {
            //proposal.status = 4u8; // Mark as expired/canceled


 let proposal_expired:Proposal =  Proposal {
        id: proposal.id,
        creator:  proposal.creator,
        description:  proposal.description,
        proposal_type:  proposal.proposal_type,
        vote_type:  proposal.vote_type,
        options_count:  proposal.options_count,
        treasury_action:  proposal.treasury_action,
        status:  4u8,
        discussion_end_time:  proposal.discussion_end_time,
        voting_end_time:  proposal.voting_end_time,
        grace_period_end_time:  proposal.grace_period_end_time,
        required_sponsorship:  proposal.required_sponsorship,
        total_sponsorship:  proposal.total_sponsorship,
        veto_count:  proposal.veto_count + calculate_voting_power(token_amount,token_locked_until),
        veto_threshold:  proposal.veto_threshold,
        amendment_count:  proposal.amendment_count,
        parent_proposal:  proposal.parent_proposal,
        tags:  proposal.tags,
        category:  proposal.category,
        min_participation:  proposal.min_participation,
        security_level: proposal.security_level,
    };



            Mapping::set(proposals, proposal_id, proposal_expired);
        }

    }


    // @note Execute Proposal
    async transition execute_proposal(proposal_id: field) -> Future {
        return finalize_execute_proposal(proposal_id);
    }

    async function finalize_execute_proposal(proposal_id: field){
        let  proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        // Ensure proposal is in grace period, hasn't been executed, and not vetoed
        assert(proposal.status == 2u8 && block.height >= proposal.grace_period_end_time);
        assert(proposal.veto_count < proposal.veto_threshold);

        let vote_aggregate: VoteAggregate = Mapping::get(vote_aggregates, proposal_id);
        
        // Check if quorum is reached
        let total_votes: u64 = vote_aggregate.vote_tally[0u8] + vote_aggregate.vote_tally[1u8];
        assert(total_votes >= proposal.min_participation);

        // Check if the proposal passed (simple majority for this example)
        let passed: bool = vote_aggregate.vote_tally[0u8] > total_votes / 2u64;
        if passed {
  
        // Continuing from the previous execute_proposal finalize function
        if proposal.security_level == 2u8 {
            // For critical proposals, initiate multi-sig process
    
            let multisig_proposal: MultiSigProposal = MultiSigProposal {
                proposal_id: proposal_id,
                approvals: 0u8,
                required_approvals: 3u8, // Assuming we require 3 approvals for critical proposals
            };

            Mapping::set(multisig_proposals, proposal_id, multisig_proposal);

            } else {
                // Execute based on proposal type
                if proposal.proposal_type == 0u8 {
                    let action:TreasuryAction = proposal.treasury_action;

                    let current_balance: TreasuryBalance = Mapping::get_or_use(treasury, action.asset, TreasuryBalance { asset: action.asset, amount: 0u64 });
                    
                    if action.action_type == 0u8 { // Transfer
                        assert(current_balance.amount >= action.amount);
                        Mapping::set(treasury, action.asset, TreasuryBalance {
                            asset: action.asset,
                            amount: current_balance.amount - action.amount,
                        });
                        // In a real implementation, you would transfer the tokens to the recipient here
                    } else if action.action_type == 1u8 { // Mint
                        Mapping::set(treasury, action.asset, TreasuryBalance {
                            asset: action.asset,
                            amount: current_balance.amount + action.amount,
                        });
                    } else if action.action_type == 2u8 { // Burn
                        assert(current_balance.amount >= action.amount);
                        Mapping::set(treasury, action.asset, TreasuryBalance {
                            asset: action.asset,
                            amount: current_balance.amount - action.amount,
                        });
                    }


                } else if proposal.proposal_type == 1u8 {
                    //execute_parameter_change(proposal_id);

                    let current_params: DAO_Parameters = Mapping::get_or_use(dao_parameters, 0field, DAO_Parameters {
                        quorum_threshold: 100_000_000_000u64,
                        voting_period: 604_800u32, // 1 week
                        grace_period: 172_800u32, // 2 days
                    });

                    // Assuming the proposal contains the new parameter values
                    let new_params: DAO_Parameters = DAO_Parameters {
                        quorum_threshold: proposal.treasury_action.amount, // Repurposing this field for parameter change
                        voting_period: proposal.voting_end_time - proposal.discussion_end_time,
                        grace_period: proposal.grace_period_end_time - proposal.voting_end_time,
                    };

                    Mapping::set(dao_parameters, 0field, new_params);



                } else if proposal.proposal_type == 2u8 {

                    // In Leo, we can't directly upgrade contracts.
                    // Instead, we can set a flag indicating that an upgrade is ready,
                    // and the actual upgrade would be performed off-chain.    
                    // Assuming we use the 'description' field to store the new contract address or version
                    let upgrade_info: field = proposal.description;
                    
                    // Set an 'upgrade_ready' flag in a mapping
                    Mapping::set(contract_upgrades, 0field, upgrade_info);


                } else if proposal.proposal_type == 3u8 {


                    //Slash a proposal
                    let slash_proposal: SlashingProposal = Mapping::get(slashing_proposals, proposal_id);
                    let  rep: DelegateeReputation = Mapping::get(delegatee_reputations, slash_proposal.target);

                    // Apply reputation decay before slashing
                    let time_elapsed: u32 = block.height - rep.last_update_time;

                    let rep_new:DelegateeReputation = DelegateeReputation {
                            delegatee_address: rep.delegatee_address,
                            category: rep.category,
                            reputation_score: calculate_reputation_decay(rep.reputation_score, time_elapsed) - slash_proposal.amount as u64,
                            proposals_supported: rep.proposals_supported,
                            proposals_succeeded: rep.proposals_succeeded,
                            last_update_time: block.height,
                        };


                    Mapping::set(delegatee_reputations, slash_proposal.target, rep_new);

                    // Remove the slashing proposal
                    Mapping::remove(slashing_proposals, proposal_id);

                            }
                    let proposal_executed:Proposal =  Proposal {
                            id: proposal.id,
                            creator:  proposal.creator,
                            description:  proposal.description,
                            proposal_type:  proposal.proposal_type,
                            vote_type:  proposal.vote_type,
                            options_count:  proposal.options_count,
                            treasury_action:  proposal.treasury_action,
                            status:  3u8,
                            discussion_end_time:  proposal.discussion_end_time,
                            voting_end_time:  proposal.voting_end_time,
                            grace_period_end_time:  proposal.grace_period_end_time,
                            required_sponsorship:  proposal.required_sponsorship,
                            total_sponsorship:  proposal.total_sponsorship,
                            veto_count:  proposal.veto_count,
                            veto_threshold:  proposal.veto_threshold,
                            amendment_count:  proposal.amendment_count,
                            parent_proposal:  proposal.parent_proposal,
                            tags:  proposal.tags,
                            category:  proposal.category,
                            min_participation:  proposal.min_participation,
                            security_level: proposal.security_level,
                        };

                            // Mark proposal as executed
                            //proposal.status = 3u8;
                            Mapping::set(proposals, proposal_id, proposal_executed);

                            // Update reputation of proposal creator
                            let  creator_reputation: Reputation = Mapping::get(user_reputation, proposal.creator);


                            let creator_reputation_new:Reputation = Reputation {
                                score: creator_reputation.score + 100i64,
                                proposal_count: creator_reputation.proposal_count,
                                vote_count: creator_reputation.vote_count,
                                successful_proposals: creator_reputation.successful_proposals + 1u32,
                            };

                            Mapping::set(user_reputation, proposal.creator, creator_reputation);



                // TODO:Update delegatee reputations
              
            }

        }


        let proposal_expired:Proposal =  Proposal {
                id: proposal.id,
                creator:  proposal.creator,
                description:  proposal.description,
                proposal_type:  proposal.proposal_type,
                vote_type:  proposal.vote_type,
                options_count:  proposal.options_count,
                treasury_action:  proposal.treasury_action,
                status:  4u8,
                discussion_end_time:  proposal.discussion_end_time,
                voting_end_time:  proposal.voting_end_time,
                grace_period_end_time:  proposal.grace_period_end_time,
                required_sponsorship:  proposal.required_sponsorship,
                total_sponsorship:  proposal.total_sponsorship,
                veto_count:  proposal.veto_count,
                veto_threshold:  proposal.veto_threshold,
                amendment_count:  proposal.amendment_count,
                parent_proposal:  proposal.parent_proposal,
                tags:  proposal.tags,
                category:  proposal.category,
                min_participation:  proposal.min_participation,
                security_level: proposal.security_level,
            };

        // If the proposal didn't pass, mark it as expired
        Mapping::set(proposals, proposal_id, proposal_expired);

        // Update reputation of proposal creator for failed proposal
        let  creator_reputation: Reputation = Mapping::get(user_reputation, proposal.creator);
        //creator_reputation.score -= 50i64;

        let creator_reputation_new:Reputation = Reputation {
            score: creator_reputation.score - 50i64,
            proposal_count: creator_reputation.proposal_count,
            vote_count: creator_reputation.vote_count,
            successful_proposals: creator_reputation.successful_proposals,
        };


        Mapping::set(user_reputation, proposal.creator, creator_reputation);

        //return false;
    }

    // @note Add Comment

    async transition add_comment(proposal_id: field, content: field) -> Future {
        return finalize_add_comment(self.caller, proposal_id, content);
    }

    async function finalize_add_comment(caller: address, proposal_id: field, content: field) {
        let proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        let new_comment: Comment = Comment {
            author: caller,
            content: content,
            timestamp: block.height,
        };


        Mapping::set(proposal_comments, proposal_id, new_comment);

    }

    // @note Delegate Votes

   async  transition delegate_votes(delegatee: address, percentage: u8) -> Future {
        assert(percentage <= 100u8);

        let delegation_info: DelegationInfo = DelegationInfo {
            delegatee: delegatee,
            percentage: percentage,
        };

        return finalize_delegate_votes(self.caller, delegation_info);
    }

    async function finalize_delegate_votes(caller: address, delegation_info: DelegationInfo) {
        Mapping::set(delegations, caller, delegation_info);
    }

    // @note Delegate Category

    async transition delegate_category(delegatee: address, category: field, amount: u64, token: GovernanceToken) -> Future {
        assert(token.amount >= amount);

        return finalize_delegate_category(self.caller, delegatee, category, amount,token.owner);
    }

    async function finalize_delegate_category(caller: address, delegatee: address, category: field, amount: u64,token_owner:address)  {
        let delegatee_rep: DelegateeReputation = Mapping::get_or_use(delegatee_reputations, delegatee, 
            DelegateeReputation {
                delegatee_address: delegatee,
                category: category,
                reputation_score: 0u64,
                proposals_supported: 0u32,
                proposals_succeeded: 0u32,
                last_update_time: block.height,
            }
        );

        let delegation: Delegation = Delegation {
            delegator: token_owner,
            delegatee: delegatee,
            category: category,
            amount: amount,
            reputation: delegatee_rep.reputation_score,
        };
         

        Mapping::set(category_delegations, BHP256::hash_to_field(DelegationKey{delegator:caller,category:category}), delegation);


    }

    // @note Propose Slashing

    async transition propose_slashing(target: address, category: field, amount: i64, reason: field) -> Future {
        return finalize_propose_slashing(target, category, amount, reason);
    }

    async function finalize_propose_slashing(target: address, category: field, amount: i64, reason: field) {
        let slash_id: field = BHP256::hash_to_field(target);

        let slash_proposal: SlashingProposal = SlashingProposal {
            target: target,
            category: category,
            amount: amount,
            reason: reason,
        };

        Mapping::set(slashing_proposals, slash_id, slash_proposal);

        // In a real implementation, you'd create a regular proposal here for voting on the slash
    }


    // @note Advance Proposal Phase

    async transition advance_proposal_phase(proposal_id: field) -> Future {
        return finalize_advance_proposal_phase(proposal_id);
    }

     async function finalize_advance_proposal_phase(proposal_id: field)  {
        let  proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        if proposal.status == 0u8 && block.height >= proposal.discussion_end_time {
           // proposal.status = 1u8; // Move to voting phase

        let proposal_new:Proposal = Proposal {
                    id: proposal.id,
                    creator: proposal.creator,
                    description: proposal.description,
                    proposal_type: proposal.proposal_type,
                    vote_type: proposal.vote_type,
                    options_count: proposal.options_count,
                    treasury_action: proposal.treasury_action,
                    status: 1u8,
                    discussion_end_time: proposal.discussion_end_time,
                    voting_end_time: proposal.voting_end_time,
                    grace_period_end_time: proposal.grace_period_end_time,
                    required_sponsorship: proposal.required_sponsorship,
                    total_sponsorship: proposal.total_sponsorship,
                    veto_count: proposal.veto_count,
                    veto_threshold: proposal.veto_threshold,
                    amendment_count: proposal.amendment_count,
                    parent_proposal: proposal.parent_proposal,
                    tags: proposal.tags,
                    category: proposal.category,
                    min_participation: proposal.min_participation,
                    security_level: proposal.security_level,
                };


        } else if proposal.status == 1u8 && block.height >= proposal.voting_end_time {
           
           // Move to grace period
              let proposal_new:Proposal = Proposal {
            id: proposal.id,
            creator: proposal.creator,
            description: proposal.description,
            proposal_type: proposal.proposal_type,
            vote_type: proposal.vote_type,
            options_count: proposal.options_count,
            treasury_action: proposal.treasury_action,
            status: 2u8,
            discussion_end_time: proposal.discussion_end_time,
            voting_end_time: proposal.voting_end_time,
            grace_period_end_time: proposal.grace_period_end_time,
            required_sponsorship: proposal.required_sponsorship,
            total_sponsorship: proposal.total_sponsorship,
            veto_count: proposal.veto_count,
            veto_threshold: proposal.veto_threshold,
            amendment_count: proposal.amendment_count,
            parent_proposal: proposal.parent_proposal,
            tags: proposal.tags,
            category: proposal.category,
            min_participation: proposal.min_participation,
            security_level: proposal.security_level,
        };
        } else if proposal.status == 2u8 && block.height >= proposal.grace_period_end_time {
            // Move to executed status
            let proposal_new:Proposal = Proposal {
            id: proposal.id,
            creator: proposal.creator,
            description: proposal.description,
            proposal_type: proposal.proposal_type,
            vote_type: proposal.vote_type,
            options_count: proposal.options_count,
            treasury_action: proposal.treasury_action,
            status: 3u8,
            discussion_end_time: proposal.discussion_end_time,
            voting_end_time: proposal.voting_end_time,
            grace_period_end_time: proposal.grace_period_end_time,
            required_sponsorship: proposal.required_sponsorship,
            total_sponsorship: proposal.total_sponsorship,
            veto_count: proposal.veto_count,
            veto_threshold: proposal.veto_threshold,
            amendment_count: proposal.amendment_count,
            parent_proposal: proposal.parent_proposal,
            tags: proposal.tags,
            category: proposal.category,
            min_participation: proposal.min_participation,
            security_level: proposal.security_level,
        };


        //EXECUTE PROPOSAL

        // Ensure proposal is in grace period, hasn't been executed, and not vetoed
        assert(proposal.status == 2u8 && block.height >= proposal.grace_period_end_time);
        assert(proposal.veto_count < proposal.veto_threshold);

        let vote_aggregate: VoteAggregate = Mapping::get(vote_aggregates, proposal_id);
        
        // Check if quorum is reached
        let total_votes: u64 = vote_aggregate.vote_tally[0u8] + vote_aggregate.vote_tally[1u8];
        assert(total_votes >= proposal.min_participation);

        // Check if the proposal passed (simple majority for this example)
        let passed: bool = vote_aggregate.vote_tally[0u8] > total_votes / 2u64;
        if passed {
  
            // Continuing from the previous execute_proposal finalize function
            if proposal.security_level == 2u8 {
                // For critical proposals, initiate multi-sig process

            
                let multisig_proposal: MultiSigProposal = MultiSigProposal {
                    proposal_id: proposal_id,
                    approvals: 0u8,
                    required_approvals: 3u8, // Assuming we require 3 approvals for critical proposals
                };

                Mapping::set(multisig_proposals, proposal_id, multisig_proposal);

            } else {
                // Execute based on proposal type
                if proposal.proposal_type == 0u8 {
                    let action:TreasuryAction = proposal.treasury_action;

                    let current_balance: TreasuryBalance = Mapping::get_or_use(treasury, action.asset, TreasuryBalance { asset: action.asset, amount: 0u64 });
                    
                    if action.action_type == 0u8 { // Transfer
                        assert(current_balance.amount >= action.amount);
                        Mapping::set(treasury, action.asset, TreasuryBalance {
                            asset: action.asset,
                            amount: current_balance.amount - action.amount,
                        });
                        // In a real implementation, you would transfer the tokens to the recipient here
                    } else if action.action_type == 1u8 { // Mint
                        Mapping::set(treasury, action.asset, TreasuryBalance {
                            asset: action.asset,
                            amount: current_balance.amount + action.amount,
                        });
                    } else if action.action_type == 2u8 { // Burn
                        assert(current_balance.amount >= action.amount);
                        Mapping::set(treasury, action.asset, TreasuryBalance {
                            asset: action.asset,
                            amount: current_balance.amount - action.amount,
                        });
                    }


                } else if proposal.proposal_type == 1u8 {
                    //Parameter Change

                    let current_params: DAO_Parameters = Mapping::get_or_use(dao_parameters, 0field, DAO_Parameters {
                        quorum_threshold: 100_000_000_000u64,
                        voting_period: 604_800u32, // 1 week
                        grace_period: 172_800u32, // 2 days
                    });

                    // Assuming the proposal contains the new parameter values
                    let new_params: DAO_Parameters = DAO_Parameters {
                        quorum_threshold: proposal.treasury_action.amount, // Repurposing this field for parameter change
                        voting_period: proposal.voting_end_time - proposal.discussion_end_time,
                        grace_period: proposal.grace_period_end_time - proposal.voting_end_time,
                    };

                    Mapping::set(dao_parameters, 0field, new_params);



                } else if proposal.proposal_type == 2u8 {

                    // In Leo, we can't directly upgrade contracts.
                    // Instead, we can set a flag indicating that an upgrade is ready,
                    // and the actual upgrade would be performed off-chain.
                    
                    // Assuming we use the 'description' field to store the new contract address or version
                    let upgrade_info: field = proposal.description;
                    
                    // Set an 'upgrade_ready' flag in a mapping
                    Mapping::set(contract_upgrades, 0field, upgrade_info);


                } else if proposal.proposal_type == 3u8 {
                    //APPLY SLASHING

                    let slash_proposal: SlashingProposal = Mapping::get(slashing_proposals, proposal_id);
                    let  rep: DelegateeReputation = Mapping::get(delegatee_reputations, slash_proposal.target);

                    // Apply reputation decay before slashing
                    let time_elapsed: u32 = block.height - rep.last_update_time;


                    let rep_new:DelegateeReputation = DelegateeReputation {
                                    delegatee_address: rep.delegatee_address,
                                    category: rep.category,
                                    reputation_score: calculate_reputation_decay(rep.reputation_score, time_elapsed) - slash_proposal.amount as u64,
                                    proposals_supported: rep.proposals_supported,
                                    proposals_succeeded: rep.proposals_succeeded,
                                    last_update_time: block.height,
                                };


                    Mapping::set(delegatee_reputations, slash_proposal.target, rep_new);

                    // Remove the slashing proposal
                    Mapping::remove(slashing_proposals, proposal_id);



                }

                    // Mark proposal as executed
                    //proposal.status = 3u8;
                    let proposal_executed:Proposal = Proposal {
                        id: proposal.id,
                        creator: proposal.creator,
                        description: proposal.description,
                        proposal_type: proposal.proposal_type,
                        vote_type: proposal.vote_type,
                        options_count: proposal.options_count,
                        treasury_action: proposal.treasury_action,
                        status: 3u8,
                        discussion_end_time: proposal.discussion_end_time,
                        voting_end_time: proposal.voting_end_time,
                        grace_period_end_time: proposal.grace_period_end_time,
                        required_sponsorship: proposal.required_sponsorship,
                        total_sponsorship: proposal.total_sponsorship,
                        veto_count: proposal.veto_count,
                        veto_threshold: proposal.veto_threshold,
                        amendment_count: proposal.amendment_count,
                        parent_proposal: proposal.parent_proposal,
                        tags: proposal.tags,
                        category: proposal.category,
                        min_participation: proposal.min_participation,
                        security_level: proposal.security_level,
            };
                    Mapping::set(proposals, proposal_id, proposal_executed);

                    // Update reputation of proposal creator
                    let  creator_reputation: Reputation = Mapping::get(user_reputation, proposal.creator);

                    let creator_reputation_new:Reputation= Reputation {
                        score: creator_reputation.score + 100i64,
                        proposal_count: creator_reputation.proposal_count,
                        vote_count: creator_reputation.vote_count,
                        successful_proposals:  creator_reputation.successful_proposals + 1u32,
                    };




                Mapping::set(user_reputation, proposal.creator, creator_reputation_new);



                // TODO: Update delegatee reputations
              

            }

            //return true;
        }

        // If the proposal didn't pass, mark it as expired
        let proposal_expired:Proposal = Proposal {
            id: proposal.id,
            creator: proposal.creator,
            description: proposal.description,
            proposal_type: proposal.proposal_type,
            vote_type: proposal.vote_type,
            options_count: proposal.options_count,
            treasury_action: proposal.treasury_action,
            status: 4u8,
            discussion_end_time: proposal.discussion_end_time,
            voting_end_time: proposal.voting_end_time,
            grace_period_end_time: proposal.grace_period_end_time,
            required_sponsorship: proposal.required_sponsorship,
            total_sponsorship: proposal.total_sponsorship,
            veto_count: proposal.veto_count,
            veto_threshold: proposal.veto_threshold,
            amendment_count: proposal.amendment_count,
            parent_proposal: proposal.parent_proposal,
            tags: proposal.tags,
            category: proposal.category,
            min_participation: proposal.min_participation,
            security_level: proposal.security_level,
        };
        Mapping::set(proposals, proposal_id, proposal_expired);

        // Update reputation of proposal creator for failed proposal
        let  creator_reputation: Reputation = Mapping::get(user_reputation, proposal_expired.creator);
        //creator_reputation.score -= 50i64;

creator_reputation = Reputation {
        score: creator_reputation.score - 50i64,
        proposal_count: creator_reputation.proposal_count,
        vote_count: creator_reputation.vote_count,
        successful_proposals: creator_reputation.successful_proposals,
    };



        Mapping::set(user_reputation, proposal_expired.creator, creator_reputation);



        } else {
            // Move to voting phase

        let proposal_voting:Proposal = Proposal {
                    id: proposal.id,
                    creator: proposal.creator,
                    description: proposal.description,
                    proposal_type: proposal.proposal_type,
                    vote_type: proposal.vote_type,
                    options_count: proposal.options_count,
                    treasury_action: proposal.treasury_action,
                    status: 1u8,
                    discussion_end_time: proposal.discussion_end_time,
                    voting_end_time: proposal.voting_end_time,
                    grace_period_end_time: proposal.grace_period_end_time,
                    required_sponsorship: proposal.required_sponsorship,
                    total_sponsorship: proposal.total_sponsorship,
                    veto_count: proposal.veto_count,
                    veto_threshold: proposal.veto_threshold,
                    amendment_count: proposal.amendment_count,
                    parent_proposal: proposal.parent_proposal,
                    tags: proposal.tags,
                    category: proposal.category,
                    min_participation: proposal.min_participation,
                    security_level: proposal.security_level,
                };


        }

        Mapping::set(proposals, proposal_id, proposal);
    }


    // @note Calculate Reputation Decay

    inline calculate_reputation_decay(reputation: u64, time_elapsed: u32) -> u64 {
        // Implement your reputation decay formula here
        // This is a simple linear decay example
        let decay_rate: u64 = 1u64; // Adjust this value to control decay speed
        let decay_amount: u64 = (time_elapsed as u64) * decay_rate;
        return reputation - decay_amount;
    }

    // @note Calculate Conviction

    inline calculate_conviction(vote: ConvictionVote, current_height: u32) -> u64 {
        let time_elapsed: u32 = current_height - vote.start_time;
        let conviction: u64 = vote.amount * (1u64 - (CONVICTION_GROWTH_RATE * (time_elapsed as u64) / 1000u64 * (time_elapsed as u64)));
        return conviction;
    }

    // @note Get Governance Tier

    inline get_governance_tier(reputation_score: u64) -> u8 {
        // Implement your tier calculation logic here
        // This is a simple example
        if reputation_score < 100u64 {
            return 0u8;
        } else if reputation_score < 1000u64 {
            return 1u8;
        } else {
            return 2u8;
        }
    }





    // @note Calculate voting power

    inline calculate_voting_power(token_amount: u64, token_lock_duration: u64) -> u64 {
        // Calculate the square root using our integer square root function
        let base_power: u64 = (token_amount);
        
        // Calculate time bonus (unchanged)
        let time_bonus: u64 = 100u64 + (token_lock_duration / 2_592_000u64); // 1% bonus per month locked
        
        // Calculate and return final voting power
        return (base_power * time_bonus) / 100u64;
    }

    struct EncryptionParams {
        public_key: group,
        random: scalar,
    }

    struct HomomorphicCiphertext {
        c1: group,
        c2: group,
    }

    // @note Encrypt Vote
    function encrypt_vote(vote: u64, params: EncryptionParams) -> HomomorphicCiphertext {
        // Implement a simple ElGamal encryption
        // This is a simplified version and should not be used in production without proper review
        let g: group = group::GEN;
        let h: group = params.public_key;
        let r: scalar = params.random;
        
        let c1: group = g * r;
        let m: group = g * (vote as scalar);
        let c2: group = h * r + m;
        
        return HomomorphicCiphertext { c1: c1, c2: c2 };
    }


    // @note Cast Vote
   // Main voting transition
    async transition cast_vote(proposal_id: field, vote: u64, token: GovernanceToken) -> Future {
        //return proposal_id then finalize(self.caller, proposal_id, vote, token);
        return finalize_cast_vote(self.caller, proposal_id, vote, token.amount, token.locked_until);

    }

    async function finalize_cast_vote(voter: address, proposal_id: field, vote: u64, token_amount: u64, token_locked_until: u64) {
        let proposal: Proposal = Mapping::get(proposals, proposal_id);
        
        // Ensure proposal is in voting phase and not vetoed
        assert(proposal.status == 1u8);
        assert(proposal.veto_count < proposal.veto_threshold);
        assert(block.height >= proposal.discussion_end_time && block.height < proposal.voting_end_time);

        // Check for previous vote and remove if exists
        let previous_vote: VoteVerification = Mapping::get_or_use(vote_verifications, proposal_id, 
            VoteVerification {
                proposal_id: 0field,
                voter: ZERO_ADDRESS,
                vote_hash: 0field,
                timestamp: 0u32,
            }
        );
        if previous_vote.timestamp != 0u32 {
            // Remove previous vote from tally

        let  results: [u64; 10] = Mapping::get(vote_results, proposal_id);
        let previous_vote_value: u8 = BHP256::hash_to_field(previous_vote.vote_hash) as u8;
        //results[previous_vote_value as u64] -= previous_vote.voter as u64; // Simplified; in reality, you'd need to store and retrieve the actual previous vote weight
        Mapping::set(vote_results, proposal_id, results);
    


        }

        // Calculate voting power
        let voting_power: u64 = calculate_voting_power(token_amount, token_locked_until);

        // Apply staking bonus
        let stake: Stake = Mapping::get_or_use(stakes, voter, Stake { token_owner: voter, amount: 0u64, start_time: 0u32, duration: 0u32 });
        let staking_bonus: u64 = calculate_staking_bonus(stake, block.height);
        voting_power = voting_power + staking_bonus;

        // Check for category-specific delegation
        let delegation: Delegation = Mapping::get_or_use(category_delegations, BHP256::hash_to_field(voter), 
            Delegation { delegator: voter, delegatee: voter, category: proposal.category, amount: 0u64, reputation: 0u64 }
        );
        
        if delegation.delegatee != voter {
           // voting_power = delegation.amount;
        }

        let vote_type: VoteType = Mapping::get(vote_types, proposal_id);
        if vote_type.conviction {
            //cast_conviction_vote(proposal_id, voting_power, voter);

        let conviction_vote: ConvictionVote = ConvictionVote {
            voter: voter,
            proposal_id: proposal_id,
            amount: voting_power,
            start_time: block.height,
        };
        Mapping::set(conviction_votes, proposal_id, conviction_vote);


        } else if vote_type.quadratic {
            //TODO:cannot reassign voting_power?
           // voting_power = calculate_quadratic_voting_power(voting_power);
        }

        // Regular voting logic
     let  results: [u64; 10] = Mapping::get_or_use(vote_results, proposal_id, [0u64,0u64,0u64,0u64,0u64,0u64,0u64,0u64,0u64,0u64]);
        // TODO: Should update voting power
        Mapping::set(vote_results, proposal_id, results);



        // Create vote verification
        let vote_hash: field = BHP256::hash_to_field((voter as field) + proposal_id + (vote as field));
        let vote_verification: VoteVerification = VoteVerification {
            proposal_id: proposal_id,
            voter: voter,
            vote_hash: vote_hash,
            timestamp: block.height,
        };
        Mapping::set(vote_verifications, proposal_id, vote_verification);

        // Update user reputation for voting

        // Update delegatee reputation
        if delegation.delegatee != voter {
            let  delegatee_rep: DelegateeReputation = Mapping::get(delegatee_reputations, delegation.delegatee);
            
            
    let  delegatee_rep_new:DelegateeReputation= DelegateeReputation {
        delegatee_address: delegatee_rep.delegatee_address,
        category: delegatee_rep.category,
        reputation_score: delegatee_rep.reputation_score,
        proposals_supported: delegatee_rep.proposals_supported + 1u32,
        proposals_succeeded: delegatee_rep.proposals_succeeded,
        last_update_time: delegatee_rep.last_update_time,
    };



            Mapping::set(delegatee_reputations, delegation.delegatee, delegatee_rep_new);
        }

        // Check for automatic slashing conditions
        let minority_rule: SlashingRule = Mapping::get(slashing_rules, 0u8);
        let  voter_history: VoterHistory = Mapping::get_or_use(voter_histories, voter, VoterHistory { minority_votes: 0u32, total_votes: 0u32 });
        


        let voter_history_new:VoterHistory =  VoterHistory {
                minority_votes: voter_history.minority_votes,
                total_votes: voter_history.total_votes+1u32,
            };




        // TODO: UPDATE REPUTATION

        Mapping::set(voter_histories, voter, voter_history);


    }

    // @note Calculate Quadratic Voting Power
    inline calculate_quadratic_voting_power(amount: u64) -> u64 {
        return (amount as u128).square_root() as u64;
    }

    // @note Calculate Staking Bonus
    inline calculate_staking_bonus(stake: Stake, current_height: u32) -> u64 {
        if stake.amount == 0u64 {
            return 0u64;
        }
        let staking_duration: u32 = current_height - stake.start_time;
        return (stake.amount * staking_duration as u64) / 10000u64; // 0.01% bonus per block staked
    }

    // Additional helper functions (to be implemented)
    // function get_category_boost(voter: address, category: field) -> u64 { ... }
    // function get_majority_vote(proposal_id: field) -> u64 { ... }
    // function get_proposal_category(proposal_id: field) -> field { ... }
    // function update_reputation(voter: address, category: field, amount: i64) { ... }

    // @note Submit Vote Aggregate
    // Transition for submitting aggregated votes (for off-chain processing)
    async transition submit_vote_aggregate(proposal_id: field, vote_count: u64, vote_tally: [u64; 10], vote_merkle_root: field) -> Future {
        return finalize_submit_vote_aggregate(proposal_id, vote_count, vote_tally, vote_merkle_root);
    }

    async function finalize_submit_vote_aggregate(proposal_id: field, vote_count: u64, vote_tally: [u64; 10], vote_merkle_root: field) {
        let vote_aggregate: VoteAggregate = VoteAggregate {
            proposal_id: proposal_id,
            vote_count: vote_count,
            vote_tally: vote_tally,
            vote_merkle_root: vote_merkle_root,
        };
        Mapping::set(vote_aggregates, proposal_id, vote_aggregate);
    }

    // @note Verify Vote
    // Transition for verifying an individual vote
    async transition verify_vote(proposal_id: field, voter: address, vote: u64, merkle_proof: field) -> Future {
        return finalize_verify_vote(proposal_id, voter, vote, merkle_proof);
    }

    async function finalize_verify_vote(proposal_id: field, voter: address, vote: u64, merkle_proof: field) {
        let vote_aggregate: VoteAggregate = Mapping::get(vote_aggregates, proposal_id);
        let stored_proof: field = Mapping::get_or_use(vote_merkle_proofs, proposal_id, 0field);
        assert(stored_proof == merkle_proof);
    }
}