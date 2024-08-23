import privadao_core_v1.aleo;

program privadao_reputation_system_v1.aleo {
    // Constants
    //const REPUTATION_HALF_LIFE: u32 = 30 * 24 * 60 * 60; // 30 days in seconds
    const REPUTATION_HALF_LIFE: u32 = 2592000u32; // 30 days in seconds
    const MIN_REPUTATION: i64 = -1000i64;
    const REHABILITATION_PERIOD: u32 = 2592000u32; // 30 days in seconds
    

    // Structs
    struct Reputation {
        score: i64,
        proposal_count: u32,
        vote_count: u32,
        successful_proposals: u32,
        last_update: u32,
    }

    struct DelegateeReputation {
        address: address,
        category: field,
        reputation_score: i64,
        proposals_supported: u32,
        proposals_succeeded: u32,
        last_update_time: u32,
        rehabilitation_start: u32,
    }

    // Mappings
    mapping user_reputation: address => Reputation;
    mapping delegatee_reputations: field => DelegateeReputation;

    // Transitions
    transition update_user_reputation(user: address, change: i64) -> i64 {
        return change then finalize(user, change);
    }

    finalize update_user_reputation(user: address, change: i64) {
        let mut rep: Reputation = Mapping::get_or_use(user_reputation, user, Reputation {
            score: 0i64,
            proposal_count: 0u32,
            vote_count: 0u32,
            successful_proposals: 0u32,
            last_update: 0u32,
        });

        // Apply reputation decay
        let time_elapsed: u32 = block.height - rep.last_update;
        rep.score = calculate_reputation_decay(rep.score, time_elapsed);

        // Apply reputation change
        rep.score += change;

        // Update relevant counters
        if change > 0i64 {
            rep.successful_proposals += 1u32;
        }
        rep.proposal_count += 1u32;

        rep.last_update = block.height;

        Mapping::set(user_reputation, user, rep);
    }

    async transition update_delegatee_reputation(delegatee: address, category: field, change: i64) -> i64 {
        return change then finalize(delegatee, category, change);
    }

    async function update_delegatee_reputation(delegatee: address, category: field, change: i64) {
        let key: field = BHP256::hash_to_field(delegatee + category);
        let mut rep: DelegateeReputation = Mapping::get_or_use(delegatee_reputations, key,
            DelegateeReputation {
                address: delegatee,
                category: category,
                reputation_score: 0i64,
                proposals_supported: 0u32,
                proposals_succeeded: 0u32,
                last_update_time: block.height,
                rehabilitation_start: 0u32,
            }
        );

        // Apply reputation decay
        let time_elapsed: u32 = block.height - rep.last_update_time;
        rep.reputation_score = calculate_reputation_decay(rep.reputation_score, time_elapsed);

        // Apply reputation change
        rep.reputation_score += change;

        // Update relevant counters
        rep.proposals_supported += 1u32;
        if change > 0i64 {
            rep.proposals_succeeded += 1u32;
        }

        // Check for minimum reputation threshold
        if rep.reputation_score < MIN_REPUTATION {
            rep.reputation_score = MIN_REPUTATION;
            rep.rehabilitation_start = block.height;
        }

        // Check for rehabilitation
        if rep.rehabilitation_start != 0u32 && block.height >= rep.rehabilitation_start + REHABILITATION_PERIOD {
            rep.reputation_score = 0i64;
            rep.rehabilitation_start = 0u32;
        }

        rep.last_update_time = block.height;
        Mapping::set(delegatee_reputations, key, rep);
    }

    async transition view_user_reputation(user: address) -> Reputation {
        return Reputation { score: 0i64, proposal_count: 0u32, vote_count: 0u32, successful_proposals: 0u32, last_update: 0u32 } 
        then finalize(user);
    }

    async function view_user_reputation(user: address) -> Reputation {
        let mut rep: Reputation = Mapping::get_or_use(user_reputation, user, Reputation {
            score: 0i64,
            proposal_count: 0u32,
            vote_count: 0u32,
            successful_proposals: 0u32,
            last_update: block.height,
        });

        // Apply reputation decay
        let time_elapsed: u32 = block.height - rep.last_update;
        rep.score = calculate_reputation_decay(rep.score, time_elapsed);
        rep.last_update = block.height;

        Mapping::set(user_reputation, user, rep);

        return rep;
    }

    async transition view_delegatee_reputation(delegatee: address, category: field) -> DelegateeReputation {
        return DelegateeReputation {
            address: delegatee,
            category: category,
            reputation_score: 0i64,
            proposals_supported: 0u32,
            proposals_succeeded: 0u32,
            last_update_time: 0u32,
            rehabilitation_start: 0u32,
        } then finalize(delegatee, category);
    }

    async function view_delegatee_reputation(delegatee: address, category: field) -> DelegateeReputation {
        let key: field = BHP256::hash_to_field(delegatee + category);
        let mut rep: DelegateeReputation = Mapping::get_or_use(delegatee_reputations, key, 
            DelegateeReputation {
                address: delegatee,
                category: category,
                reputation_score: 0i64,
                proposals_supported: 0u32,
                proposals_succeeded: 0u32,
                last_update_time: block.height,
                rehabilitation_start: 0u32,
            }
        );

        // Apply reputation decay
        let time_elapsed: u32 = block.height - rep.last_update_time;
        rep.reputation_score = calculate_reputation_decay(rep.reputation_score, time_elapsed);
        rep.last_update_time = block.height;

        Mapping::set(delegatee_reputations, key, rep);

        return rep;
    }

    // Helper function to calculate reputation decay
    function calculate_reputation_decay(initial_reputation: i64, time_elapsed: u32) -> i64 {
        let decay_factor: u64 = 2u64.pow(time_elapsed / REPUTATION_HALF_LIFE);
        return initial_reputation / (decay_factor as i64);
    }
}