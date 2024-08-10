import privadao_core_v1.aleo;


// The 'privadao_reputation_system_v1' program.
program privadao_reputation_system_v1.aleo {

    struct Reputation {
        user: address,
        score: i64,
        last_update: u32,
    }

    mapping reputations: address => Reputation;

    transition update_reputation(user: address, change: i64) -> i64 {
        let mut rep: Reputation = Mapping::get_or_use(reputations, user, Reputation {
            user: user,
            score: 0i64,
            last_update: 0u32,
        });

        rep.score += change;
        rep.last_update = block.height;

        Mapping::set(reputations, user, rep);

        return rep.score;
    }

    transition view_delegatee_reputation(delegatee: address, category: field) -> DelegateeReputation {
        return Mapping::get_or_use(delegatee_reputations, (delegatee, category), 
            DelegateeReputation {
                address: delegatee,
                category: category,
                reputation_score: 0u64,
                proposals_supported: 0u32,
                proposals_succeeded: 0u32,
            }
        );
    }


    // Other reputation-related functions...
}

