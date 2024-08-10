import privadao_governance_token_v1.aleo;

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

    // Transitions
    transition initialize_dao(
        name: field,
        token_address: address,
        proposal_address: address,
        voting_address: address,
        reputation_address: address,
        treasury_address: address,
        staking_address: address
    ) -> field {
        let dao_id: field = BHP256::hash_to_field(name);
        return dao_id then async function(dao_id, name, token_address, proposal_address, voting_address, reputation_address, treasury_address, staking_address);
    }

    async function initialize_dao(
        dao_id: field,
        name: field,
        token_address: address,
        proposal_address: address,
        voting_address: address,
        reputation_address: address,
        treasury_address: address,
        staking_address: address
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
            admin: self.caller,
            can_update_config: true,
            can_update_permissions: true,
        };
        Mapping::set(dao_permissions, dao_id, permissions);
    }

    transition update_component_address(dao_id: field, component: field, new_address: address) -> bool {
        return true then async function(dao_id, component, new_address);
    }

    async function update_component_address(dao_id: field, component: field, new_address: address) {
        let permissions: DAOPermissions = Mapping::get(dao_permissions, dao_id);
        assert(permissions.admin == self.caller && permissions.can_update_config);

        let mut config: DAOConfig = Mapping::get(dao_config, dao_id);
        
        if component == field("token") {
            config.token_address = new_address;
        } else if component == field("proposal") {
            config.proposal_address = new_address;
        } else if component == field("voting") {
            config.voting_address = new_address;
        } else if component == field("reputation") {
            config.reputation_address = new_address;
        } else if component == field("treasury") {
            config.treasury_address = new_address;
        } else if component == field("staking") {
            config.staking_address = new_address;
        } else {
            assert(false); // Invalid component
        }

        Mapping::set(dao_config, dao_id, config);
    }

    transition update_permissions(dao_id: field, new_admin: address, can_update_config: bool, can_update_permissions: bool) -> bool {
        return true then async function(dao_id, new_admin, can_update_config, can_update_permissions);
    }

    async function update_permissions(dao_id: field, new_admin: address, can_update_config: bool, can_update_permissions: bool) {
        let current_permissions: DAOPermissions = Mapping::get(dao_permissions, dao_id);
        assert(current_permissions.admin == self.caller && current_permissions.can_update_permissions);

        let new_permissions: DAOPermissions = DAOPermissions {
            admin: new_admin,
            can_update_config: can_update_config,
            can_update_permissions: can_update_permissions,
        };
        Mapping::set(dao_permissions, dao_id, new_permissions);
    }

    transition view_dao_config(dao_id: field) -> DAOConfig {
        return DAOConfig {
            name: field(""),
            token_address: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
            proposal_address: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
            voting_address: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
            reputation_address: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
            treasury_address: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
            staking_address: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
        } then async function(dao_id);
    }

    async function view_dao_config(dao_id: field) -> DAOConfig {
        return Mapping::get(dao_config, dao_id);
    }

    transition view_dao_permissions(dao_id: field) -> DAOPermissions {
        return DAOPermissions {
            admin: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
            can_update_config: false,
            can_update_permissions: false,
        } then async function(dao_id);
    }

    async function view_dao_permissions(dao_id: field) -> DAOPermissions {
        return Mapping::get(dao_permissions, dao_id);
    }
}