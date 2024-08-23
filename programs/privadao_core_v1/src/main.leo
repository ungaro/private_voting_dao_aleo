//import privadao_governance_token_v1.aleo;

program privadao_core_v1.aleo {
    // Structs
    struct DAOConfig {
        name: field,
        token_address: address,
        proposal_address: address,
        voting_address: address,
        reputation_address: address,
        treasury_address: address,
        staking_address: address,
    }

    struct DAOPermissions {
        admin: address,
        can_update_config: bool,
        can_update_permissions: bool,
    }

    // Mappings
    mapping dao_config: field => DAOConfig;
    mapping dao_permissions: field => DAOPermissions;
    //mapping dao_test:field  =>Da ;

    // Transitions
    async transition initialize_dao(
        name: field,
        token_address: address,
        proposal_address: address,
        voting_address: address,
        reputation_address: address,
        treasury_address: address,
        staking_address: address
    ) -> Future {
        let dao_id: field = BHP256::hash_to_field(name);
        let caller:address = self.caller;
        return finalize_initialize_dao(dao_id, name, token_address, proposal_address, voting_address, reputation_address, treasury_address, staking_address, caller);
    }

    async function finalize_initialize_dao(
        dao_id: field,
        name: field,
        token_address: address,
        proposal_address: address,
        voting_address: address,
        reputation_address: address,
        treasury_address: address,
        staking_address: address,
        caller:address
    ) {
        let config: DAOConfig = DAOConfig {
            name: name,
            token_address: token_address,
            proposal_address: proposal_address,
            voting_address: voting_address,
            reputation_address: reputation_address,
            treasury_address: treasury_address,
            staking_address: staking_address,
        };
        Mapping::set(dao_config, dao_id, config);

        let permissions: DAOPermissions = DAOPermissions {
            admin: caller,
            can_update_config: true,
            can_update_permissions: true,
        };
        Mapping::set(dao_permissions, dao_id, permissions);
    }

    async transition update_component_address(dao_id: field, component: u8, new_address: address) -> Future {
        let caller:address = self.caller;
        return finalize_update_component_address(dao_id, component, new_address,caller);
    }


// COMPONENTS:
// TOKEN: 1
// PROPOSAL: 2
// VOTING: 3
// REPUTATION: 4
// TREASURY: 5
// STAKING: 6

    async function finalize_update_component_address(dao_id: field, component: u8, new_address: address, caller:address) {
        let permissions: DAOPermissions = Mapping::get(dao_permissions, dao_id);
        assert(permissions.admin == caller && permissions.can_update_config);

        let  config: DAOConfig = Mapping::get(dao_config, dao_id);
        


        if component == 1u8 {


        let new_config:DAOConfig = DAOConfig{
            name: config.name,
        token_address: new_address,
        proposal_address: config.proposal_address,
        voting_address: config.voting_address,
        reputation_address: config.reputation_address,
        treasury_address: config.treasury_address,
        staking_address: config.staking_address,
};
        Mapping::set(dao_config, dao_id, new_config);

        } else if component == 2u8 {
          //  config.proposal_address = new_address;

        let new_config:DAOConfig = DAOConfig{
            name: config.name,
        token_address: config.token_address,
        proposal_address: new_address,
        voting_address: config.voting_address,
        reputation_address: config.reputation_address,
        treasury_address: config.treasury_address,
        staking_address: config.staking_address,
};
        Mapping::set(dao_config, dao_id, new_config);


        } else if component == 3u8 {
            //config.voting_address = new_address;
        let new_config:DAOConfig = DAOConfig{
            name: config.name,
        token_address: config.token_address,
        proposal_address: config.proposal_address,
        voting_address: new_address,
        reputation_address: config.reputation_address,
        treasury_address: config.treasury_address,
        staking_address: config.staking_address,
};
        Mapping::set(dao_config, dao_id, new_config);

        } else if component == 4u8 {
            //config.reputation_address = new_address;
        let new_config:DAOConfig = DAOConfig{
            name: config.name,
            token_address: config.token_address,
            proposal_address: config.proposal_address,
            voting_address: config.voting_address,
            reputation_address: new_address,
            treasury_address: config.treasury_address,
            staking_address: config.staking_address,
        };
                Mapping::set(dao_config, dao_id, new_config);

        } else if component == 5u8 {
        let new_config:DAOConfig = DAOConfig{
            name: config.name,
            token_address: config.token_address,
            proposal_address: config.proposal_address,
            voting_address: config.voting_address,
            reputation_address: config.reputation_address,
            treasury_address: new_address,
            staking_address: config.staking_address,
        };
                        Mapping::set(dao_config, dao_id, new_config);

        } else if component == 6u8 {
            //config.staking_address = new_address;
        let new_config:DAOConfig = DAOConfig{
            name: config.name,
            token_address: config.token_address,
            proposal_address: config.proposal_address,
            voting_address: config.voting_address,
            reputation_address: config.reputation_address,
            treasury_address: config.treasury_address,
            staking_address: new_address,
        };
                                Mapping::set(dao_config, dao_id, new_config);

        } else {
            assert(false); // Invalid component
        }

    }

    async transition update_permissions(dao_id: field, new_admin: address, can_update_config: bool, can_update_permissions: bool) -> Future {
        let caller:address = self.caller;
        return finalize_update_permissions(dao_id, new_admin, can_update_config, can_update_permissions,caller);
    }

    async function finalize_update_permissions(dao_id: field, new_admin: address, can_update_config: bool, can_update_permissions: bool, caller:address) {
        let current_permissions: DAOPermissions = Mapping::get(dao_permissions, dao_id);
        assert(current_permissions.admin == caller && current_permissions.can_update_permissions);

        let new_permissions: DAOPermissions = DAOPermissions {
            admin: new_admin,
            can_update_config: can_update_config,
            can_update_permissions: can_update_permissions,
        };
        Mapping::set(dao_permissions, dao_id, new_permissions);
    }



/*
view_dao_config
GET /testnet/program/privadao_core_v1/mapping/DAOConfig/dao_id


view_dao_permissions
GET /testnet/program/privadao_core_v1/mapping/dao_permissions/dao_id


*/

}