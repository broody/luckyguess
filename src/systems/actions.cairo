use luckyguess::models::coin_flip::CoinSide;
use luckyguess::models::config::Config;

// Interface definition
#[starknet::interface]
pub trait IActions<T> {
    fn place_bet(ref self: T, bet_amount: u32, chosen_side: CoinSide) -> u32;
    fn resolve_bet(ref self: T, game_id: u32);
    fn update_config(ref self: T, config: Option<Config>);
}

#[dojo::contract]
mod actions {
    use starknet::{ContractAddress, get_caller_address, get_block_info};
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo::world::IWorldDispatcherTrait;

    use luckyguess::models::coin_flip::{
        CoinFlipGame, CoinSide, GameStatus, CoinFlipGameTrait,
    };
    use luckyguess::models::config::{
        Config, ConfigTrait, ConfigImpl, WORLD_RESOURCE
    };
    use luckyguess::random::RandomImpl;

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct BetPlaced {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        bet_amount: u32,
        chosen_side: CoinSide,
        block_number: u64,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct BetResolved {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        chosen_side: CoinSide,
        actual_result: CoinSide,
        won: bool,
        payout_amount: u32,
        block_number: u64,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct ConfigUpdated {
        #[key]
        updater: ContractAddress,
        house_edge_basis_points: u16,
        min_bet_amount: u32,
        max_bet_amount: u32,
        is_paused: bool,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of super::IActions<ContractState> {
        fn place_bet(ref self: ContractState, bet_amount: u32, chosen_side: CoinSide) -> u32 {
            let player = get_caller_address();
            let block_info = get_block_info().unbox();
            let current_block = block_info.block_number;
            let current_timestamp = block_info.block_timestamp;
            let mut world = self.world(@"luckyguess");

            // Get or create config
            let config: Config = world.read_model(WORLD_RESOURCE);

            // Validate game state and bet amount
            assert(!config.is_game_paused(), 'Game is paused');
            assert(config.is_valid_bet_amount(bet_amount), 'Invalid bet amount');

            // Generate unique game ID using dojo's uuid
            let game_id = world.dispatcher.uuid();

            // Create and place bet in one transaction
            let new_game = CoinFlipGame {
                game_id,
                player,
                bet_amount,
                chosen_side: Option::Some(chosen_side),
                actual_result: Option::None,
                status: GameStatus::Pending,
                house_edge_basis_points: config.house_edge_basis_points,
                payout_amount: 0,
                bet_block_number: current_block,
                resolve_block_number: 0,
                timestamp: current_timestamp,
            };

            // Store the game
            world.write_model(@new_game);

            // Emit event
            world
                .emit_event(
                    @BetPlaced {
                        game_id, player, bet_amount, chosen_side, block_number: current_block,
                    },
                );

            game_id
        }

        fn resolve_bet(ref self: ContractState, game_id: u32) {
            let player = get_caller_address();
            let block_info = get_block_info().unbox();
            let current_block = block_info.block_number;
            let mut world = self.world(@"luckyguess");

            // Get config for max blocks
            let config: Config = world.read_model(WORLD_RESOURCE);

            // Get the game
            let mut game: CoinFlipGame = world.read_model((game_id, player));

            // Validate game can be resolved
            assert(game.status == GameStatus::Pending, 'Game not pending');
            assert(game.bet_amount > 0, 'No bet placed');
            assert(game.chosen_side.is_some(), 'No side chosen');
            assert(game.can_resolve(current_block), 'Must wait for next block');
            assert(!game.is_expired(current_block, config.max_blocks_to_resolve), 'Game expired');

            // Use random boolean to determine coin flip result
            let mut random = RandomImpl::new();
            let is_heads = random.bool();
            let actual_result = if is_heads {
                CoinSide::Heads
            } else {
                CoinSide::Tails
            };

            // Calculate payout if player won
            let chosen_side = game.chosen_side.unwrap();
            let payout_amount = if chosen_side == actual_result {
                config.calculate_payout(game.bet_amount)
            } else {
                0
            };

            // Update game state
            game.actual_result = Option::Some(actual_result);
            game.status = GameStatus::Completed;
            game.payout_amount = payout_amount;
            game.resolve_block_number = current_block;

            // Store updated game
            world.write_model(@game);

            // Emit event
            world
                .emit_event(
                    @BetResolved {
                        game_id,
                        player,
                        chosen_side,
                        actual_result,
                        won: chosen_side == actual_result,
                        payout_amount,
                        block_number: current_block,
                    },
                );
        }

        fn update_config(ref self: ContractState, config: Option<Config>) {
            let owner = get_caller_address();
            let mut world = self.world(@"luckyguess");
            assert!(world.dispatcher.is_owner(WORLD_RESOURCE, owner), "Unauthorized owner");

            let new_config = config.unwrap_or(ConfigImpl::default());
            world.write_model(@new_config);

            // Emit event
            world.emit_event(@ConfigUpdated {
                updater: owner,
                house_edge_basis_points: new_config.house_edge_basis_points,
                min_bet_amount: new_config.min_bet_amount,
                max_bet_amount: new_config.max_bet_amount,
                is_paused: new_config.is_paused,
            });
        }
    }
}
