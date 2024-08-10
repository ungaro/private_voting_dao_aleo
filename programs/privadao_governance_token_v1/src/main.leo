import privadao_core_v1.aleo;

program privadao_governance_token_v1.aleo {
    // Records
    record Token {
        owner: address,
        amount: u64,
    }

    record GovernanceToken {
        owner: address,
        amount: u64,
        locked_until: u32,
    }

    // Structs
    struct Sponsorship {
        sponsor: address,
        amount: u64,
    }

    struct GovernanceTier {
        name: field,
        min_reputation: i64,
        proposal_types: [u8; 5], // Array of allowed proposal types for this tier
    }

    // Mappings
    mapping token_balances: address => u64;
    mapping governance_token_balance: address => u64;
    mapping governance_tiers: u8 => GovernanceTier;

    // Transitions
    transition mint(receiver: address, amount: u64) -> Token {
        finalize_mint(receiver, amount);

    }

    async function finalize_mint(receiver: address, amount: u64) {
        let current_balance: u64 = Mapping::get_or_use(token_balances, receiver, 0u64);
        Mapping::set(token_balances, receiver, current_balance + amount);
          return Token {
            owner: receiver,
            amount: amount,
        }
    }

    transition transfer(sender: Token, receiver: address, amount: u64) -> (Token, Token) {
        assert(sender.amount >= amount);
        
        let recipient_token: Token = Token {
            owner: receiver,
            amount: amount,
        };

        let sender_token: Token = Token {
            owner: sender.owner,
            amount: sender.amount - amount,
        };

        finalize_transfer(sender.owner, receiver, amount);
    }

    async function finalize_transfer(sender: address, receiver: address, amount: u64) {
        let sender_balance: u64 = Mapping::get_or_use(token_balances, sender, 0u64);
        let receiver_balance: u64 = Mapping::get_or_use(token_balances, receiver, 0u64);
        
        Mapping::set(token_balances, sender, sender_balance - amount);
        Mapping::set(token_balances, receiver, receiver_balance + amount);
return (recipient_token, sender_token)
    }

    async transition mint_governance_token(receiver: address, amount: u64, lock_duration: u32) -> GovernanceToken {
        finalize_mint_governance_token(receiver, amount);
    }

    async function mint_governance_token(receiver: address, amount: u64) {
        let current_balance: u64 = Mapping::get_or_use(governance_token_balance, receiver, 0u64);
        Mapping::set(governance_token_balance, receiver, current_balance + amount);
          return GovernanceToken {
            owner: receiver,
            amount: amount,
            locked_until: block.height + lock_duration,
        }
    }

    transition transfer_governance_token(sender: GovernanceToken, receiver: address, amount: u64) -> (GovernanceToken, GovernanceToken) {
        assert(sender.amount >= amount);
        assert(block.height >= sender.locked_until);
        

          finalize_transfer_governance_token(sender.owner, receiver, amount);
    }

    finalize transfer_governance_token(sender: address, receiver: address, amount: u64) {
        let sender_balance: u64 = Mapping::get_or_use(governance_token_balance, sender, 0u64);
        let receiver_balance: u64 = Mapping::get_or_use(governance_token_balance, receiver, 0u64);
        
                let recipient_token: GovernanceToken = GovernanceToken {
            owner: receiver,
            amount: amount,
            locked_until: sender.locked_until,
        };

        let sender_token: GovernanceToken = GovernanceToken {
            owner: sender.owner,
            amount: sender.amount - amount,
            locked_until: sender.locked_until,
        };

        Mapping::set(governance_token_balance, sender, sender_balance - amount);
        Mapping::set(governance_token_balance, receiver, receiver_balance + amount);



        return (recipient_token, sender_token)
    }

    async transition set_governance_tier(tier: u8, name: field, min_reputation: i64, proposal_types: [u8; 5]) -> bool {
        finalize_set_governance_tier(tier, name, min_reputation, proposal_types);
    }

    async function finalize_set_governance_tier(tier: u8, name: field, min_reputation: i64, proposal_types: [u8; 5]) {
        let governance_tier: GovernanceTier = GovernanceTier {
            name: name,
            min_reputation: min_reputation,
            proposal_types: proposal_types,
        };
        Mapping::set(governance_tiers, tier, governance_tier);
         return true 
    }

    transition get_governance_tier(reputation: i64) -> u8 {
        if reputation >= 1000i64 {
            return 3u8; // Highest tier
        } else if reputation >= 500i64 {
            return 2u8; // Mid tier
        } else if reputation >= 100i64 {
            return 1u8; // Low tier
        } else {
            return 0u8; // Base tier
        }
    }

    transition view_balance(account: address) -> u64 {
        return 0u64 then finalize(account);
    }

    finalize view_balance(account: address) -> u64 {
        return Mapping::get_or_use(token_balances, account, 0u64);
    }

    transition view_governance_balance(account: address) -> u64 {
        return 0u64 then finalize(account);
    }

    finalize view_governance_balance(account: address) -> u64 {
        return Mapping::get_or_use(governance_token_balance, account, 0u64);
    }
}