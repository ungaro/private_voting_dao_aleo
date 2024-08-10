import privadao_core_v1.aleo;


program privadao_governance_token_v1.aleo {
    // Import core DAO for configuration

    record Token {
        owner: address,
        amount: u64,
    }

    record GovernanceToken {
        owner: address,
        amount: u64,
        locked_until: u32,
    }

  // New struct for proposal sponsorship
    struct Sponsorship {
        sponsor: address,
        amount: u64,
    }

    mapping token_balances: address => u64;

    transition mint(receiver: address, amount: u64) -> Token {
        let current_balance: u64 = Mapping::get_or_use(token_balances, receiver, 0u64);
        Mapping::set(token_balances, receiver, current_balance + amount);

        return Token {
            owner: receiver,
            amount: amount,
        };
    }

    transition transfer(sender: Token, receiver: address, amount: u64) -> (Token, Token) {
        let remaining: u64 = sender.amount - amount;

        let recipient_token: Token = Token {
            owner: receiver,
            amount: amount,
        };

        let sender_token: Token = Token {
            owner: sender.owner,
            amount: remaining,
        };

        return (recipient_token, sender_token);
    }


    // Transition to mint governance tokens
    transition mint_governance_tokens(receiver: address, amount: u64) -> GovernanceToken {
        let current_balance: u64 = Mapping::get_or_use(governance_token_balance, receiver, 0u64);
        Mapping::set(governance_token_balance, receiver, current_balance + amount);

        return GovernanceToken {
            owner: receiver,
            amount: amount,
        };
    }

   // Transition to create a new governance token with lock-up
    transition mint_governance_token(receiver: address, amount: u64, lock_duration: u32) -> GovernanceToken {
        let current_balance: u64 = Mapping::get_or_use(governance_token_balance, receiver, 0u64);
        Mapping::set(governance_token_balance, receiver, current_balance + amount);

        return GovernanceToken {
            owner: receiver,
            amount: amount,
            locked_until: block.height + lock_duration,
        };
    }


    // Other token-related functions...
}