use luckyguess::models::config::Config;

// Interface definition for config management
#[starknet::interface]
pub trait IConfigActions<T> {
    fn pause_game(ref self: T);
    fn unpause_game(ref self: T);
    fn set_house_edge(ref self: T, house_edge_basis_points: u16);
    fn set_bet_limits(ref self: T, min_bet_amount: u256, max_bet_amount: u256);
    fn set_use_vrf(ref self: T, use_vrf: bool);
    fn set_max_blocks_to_resolve(ref self: T, max_blocks: u64);
    fn initialize_config(ref self: T);
    fn get_config(self: @T) -> Config;
}

#[dojo::contract]
mod config_actions {
    use starknet::{ContractAddress, get_caller_address};
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo::world::IWorldDispatcherTrait;
    
    use luckyguess::models::config::{
        Config, ConfigImpl, WORLD_RESOURCE
    };

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct GamePaused {
        #[key]
        admin: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct GameUnpaused {
        #[key]
        admin: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct HouseEdgeUpdated {
        #[key]
        admin: ContractAddress,
        old_house_edge: u16,
        new_house_edge: u16,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct BetLimitsUpdated {
        #[key]
        admin: ContractAddress,
        min_bet_amount: u256,
        max_bet_amount: u256,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct VrfSettingUpdated {
        #[key]
        admin: ContractAddress,
        use_vrf: bool,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct MaxBlocksUpdated {
        #[key]
        admin: ContractAddress,
        max_blocks: u64,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct ConfigInitialized {
        #[key]
        admin: ContractAddress,
        config: Config,
    }

    #[abi(embed_v0)]
    impl ConfigActionsImpl of super::IConfigActions<ContractState> {
        fn pause_game(ref self: ContractState) {
            let admin = get_caller_address();
            let mut world = self.world(@"luckyguess");
            
            // Check admin permissions
            assert!(world.dispatcher.is_owner(WORLD_RESOURCE, admin), "Unauthorized admin");

            // Get current config
            let mut config: Config = world.read_model(WORLD_RESOURCE);
            
            // Update pause status
            config.is_paused = true;
            world.write_model(@config);

            // Emit event
            world.emit_event(@GamePaused {
                admin,
                timestamp: starknet::get_block_timestamp(),
            });
        }

        fn unpause_game(ref self: ContractState) {
            let admin = get_caller_address();
            let mut world = self.world(@"luckyguess");
            
            // Check admin permissions
            assert!(world.dispatcher.is_owner(WORLD_RESOURCE, admin), "Unauthorized admin");

            // Get current config
            let mut config: Config = world.read_model(WORLD_RESOURCE);
            
            // Update pause status
            config.is_paused = false;
            world.write_model(@config);

            // Emit event
            world.emit_event(@GameUnpaused {
                admin,
                timestamp: starknet::get_block_timestamp(),
            });
        }

        fn set_house_edge(ref self: ContractState, house_edge_basis_points: u16) {
            let admin = get_caller_address();
            let mut world = self.world(@"luckyguess");
            
            // Check admin permissions
            assert!(world.dispatcher.is_owner(WORLD_RESOURCE, admin), "Unauthorized admin");
            
            // Validate house edge (max 10% = 1000 basis points)
            assert(house_edge_basis_points <= 1000, 'House edge too high');

            // Get current config
            let mut config: Config = world.read_model(WORLD_RESOURCE);
            let old_house_edge = config.house_edge_basis_points;
            
            // Update house edge
            config.house_edge_basis_points = house_edge_basis_points;
            world.write_model(@config);

            // Emit event
            world.emit_event(@HouseEdgeUpdated {
                admin,
                old_house_edge,
                new_house_edge: house_edge_basis_points,
            });
        }

        fn set_bet_limits(ref self: ContractState, min_bet_amount: u256, max_bet_amount: u256) {
            let admin = get_caller_address();
            let mut world = self.world(@"luckyguess");
            
            // Check admin permissions
            assert!(world.dispatcher.is_owner(WORLD_RESOURCE, admin), "Unauthorized admin");
            
            // Validate bet limits
            assert(min_bet_amount > 0, 'Min bet must be positive');
            assert(max_bet_amount >= min_bet_amount, 'Max bet must be >= min bet');

            // Get current config
            let mut config: Config = world.read_model(WORLD_RESOURCE);
            
            // Update bet limits
            config.min_bet_amount = min_bet_amount;
            config.max_bet_amount = max_bet_amount;
            world.write_model(@config);

            // Emit event
            world.emit_event(@BetLimitsUpdated {
                admin,
                min_bet_amount,
                max_bet_amount,
            });
        }

        fn set_use_vrf(ref self: ContractState, use_vrf: bool) {
            let admin = get_caller_address();
            let mut world = self.world(@"luckyguess");
            
            // Check admin permissions
            assert!(world.dispatcher.is_owner(WORLD_RESOURCE, admin), "Unauthorized admin");

            // Get current config
            let mut config: Config = world.read_model(WORLD_RESOURCE);
            
            // Update VRF setting
            config.use_vrf = use_vrf;
            world.write_model(@config);

            // Emit event
            world.emit_event(@VrfSettingUpdated {
                admin,
                use_vrf,
            });
        }

        fn set_max_blocks_to_resolve(ref self: ContractState, max_blocks: u64) {
            let admin = get_caller_address();
            let mut world = self.world(@"luckyguess");
            
            // Check admin permissions
            assert!(world.dispatcher.is_owner(WORLD_RESOURCE, admin), "Unauthorized admin");
            
            // Validate max blocks (reasonable range)
            assert(max_blocks > 0 && max_blocks <= 100, 'Invalid max blocks range');

            // Get current config
            let mut config: Config = world.read_model(WORLD_RESOURCE);
            
            // Update max blocks
            config.max_blocks_to_resolve = max_blocks;
            world.write_model(@config);

            // Emit event
            world.emit_event(@MaxBlocksUpdated {
                admin,
                max_blocks,
            });
        }

        fn initialize_config(ref self: ContractState) {
            let admin = get_caller_address();
            let mut world = self.world(@"luckyguess");
            
            // Check admin permissions
            assert!(world.dispatcher.is_owner(WORLD_RESOURCE, admin), "Unauthorized admin");

            // Create default config
            let config = ConfigImpl::default();
            world.write_model(@config);

            // Emit event
            world.emit_event(@ConfigInitialized {
                admin,
                config,
            });
        }

        fn get_config(self: @ContractState) -> Config {
            let world = self.world(@"luckyguess");
            world.read_model(WORLD_RESOURCE)
        }
    }
} 