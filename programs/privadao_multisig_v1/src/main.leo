// The 'privadao_multisig_v1' program.
program privadao_multisig_v1.aleo {

    // Modified struct for multi-sig proposals
    struct MultiSigProposal {
        id: field,
        description: field,
        required_signatures: u32,
        signature_count: u32,
        executed: bool,
    }

    // New transition to create a multi-sig proposal
    transition create_multisig_proposal(description: field, required_signatures: u32) -> field {
        let proposal_id: field = BHP256::hash_to_field(description);

        let new_proposal: MultiSigProposal = MultiSigProposal {
            id: proposal_id,
            description: description,
            required_signatures: required_signatures,
            signature_count: 10u32, 
            executed: false,
        };

        Mapping::set(multisig_proposals, proposal_id, new_proposal);

        return proposal_id;
    }



    async transition sign_multisig_proposal(proposal_id: field)  -> Future {
        return finalize_sign_multisig_proposal(proposal_id);
    }

    async function finalize_sign_multisig_proposal(proposal_id: field) {
        let mut proposal: MultiSigProposal = Mapping::get(multisig_proposals, proposal_id);

        assert(!proposal.executed);

        // Check if the caller has already signed
        let mut already_signed: bool = false;
        for i: u8 in 0u8..10u8 {
            if proposal.signers[i] == self.caller {
                already_signed = true;
                break;
            }
        }
        assert(!already_signed);

        // Add the new signer
        for i: u8 in 0u8..10u8 {
            if proposal.signers[i] == self.caller {
                proposal.signers[i] = self.caller;
                break;
            }
        }

        // Check if we have enough signatures to execute
        let mut signature_count: u8 = 0u8;
        for i: u8 in 0u8..10u8 {
            if proposal.signers[i] != self.caller {
                signature_count += 1u8;
            }
        }

        if signature_count >= proposal.required_signatures {
            proposal.executed = true;
            // In a real implementation, we would execute the proposal action here
        }

        Mapping::set(multisig_proposals, proposal_id, proposal);

        return proposal.executed;


/*
        let mut proposal: MultiSigProposal = Mapping::get(multisig_proposals, proposal_id);

        assert(!proposal.executed);

        let signer_id: field = BHP256::hash_to_field(self.caller);
        let is_new_signer: bool = Mapping::get_or_use(multisig_signers, proposal_id, 0field) != signer_id;

        if is_new_signer {
            proposal.signature_count += 1u32;
            Mapping::set(multisig_signers, proposal_id, signer_id);
        }

        if proposal.signature_count >= proposal.required_signatures {
            proposal.executed = true;
            // In a real implementation, we would execute the proposal action here
        }

        Mapping::set(multisig_proposals, proposal_id, proposal);

        return proposal.executed;
*/


    }



}
