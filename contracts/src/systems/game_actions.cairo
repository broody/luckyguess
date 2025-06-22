use luckyguess::models::coin_flip::CoinSide;

// Interface definition
#[starknet::interface]
pub trait IGameActions<T> {
    fn flip_coin(ref self: T, bet_amount: u256, chosen_side: CoinSide) -> (u32, bool, u256);
}

#[dojo::contract]
mod game_actions {
    use starknet::{ContractAddress, get_caller_address, get_block_info};
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo::world::IWorldDispatcherTrait;

    use luckyguess::models::coin_flip::{
        CoinFlipGame, CoinSide
    };
    use luckyguess::models::config::{
        Config, ConfigTrait, WORLD_RESOURCE
    };
    use luckyguess::models::player::{
        CoinFlipPlayerStats, CoinFlipPlayerStatsTrait
    };
    use luckyguess::random::RandomImpl;

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct GamePlayed {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        bet_amount: u256,
        chosen_side: CoinSide,
        actual_result: CoinSide,
        won: bool,
        payout_amount: u256,
        block_number: u64,
        timestamp: u64,
    }

    #[abi(embed_v0)]
    impl GameActionsImpl of super::IGameActions<ContractState> {
        fn flip_coin(ref self: ContractState, bet_amount: u256, chosen_side: CoinSide) -> (u32, bool, u256) {
            let player = get_caller_address();
            let block_info = get_block_info().unbox();
            let current_block = block_info.block_number;
            let current_timestamp = block_info.block_timestamp;
            let mut world = self.world(@"luckyguess");

            // Get config
            let config: Config = world.read_model(WORLD_RESOURCE);

            // Validate game state and bet amount
            assert(!config.is_game_paused(), 'Game is paused');
            assert(config.is_valid_bet_amount(bet_amount), 'Invalid bet amount');

            // Generate unique game ID using dojo's uuid
            let game_id = world.dispatcher.uuid();

            // Get random result using VRF or regular random based on config
            let mut random = if config.use_vrf {
                RandomImpl::new_vrf()
            } else {
                RandomImpl::new()
            };
            let is_heads = random.bool();
            let actual_result = if is_heads {
                CoinSide::Heads
            } else {
                CoinSide::Tails
            };

            // Check if player won
            let player_won = chosen_side == actual_result;

            // Calculate payout if player won (house edge built into payout calculation)
            let payout_amount = if player_won {
                config.calculate_payout(bet_amount)
            } else {
                0
            };

            // Create and store the completed game
            let completed_game = CoinFlipGame {
                game_id,
                player,
                bet_amount,
                chosen_side,
                actual_result,
                house_edge_basis_points: config.house_edge_basis_points,
                payout_amount,
                block_number: current_block,
                timestamp: current_timestamp,
            };

            // Store the game
            world.write_model(@completed_game);

            // Update player statistics
            let mut player_stats: CoinFlipPlayerStats = world.read_model(player);
            player_stats.update_after_game(bet_amount, payout_amount, player_won, current_timestamp);
            world.write_model(@player_stats);

            // Emit single event with all game info
            world.emit_event(@GamePlayed {
                game_id,
                player,
                bet_amount,
                chosen_side,
                actual_result,
                won: player_won,
                payout_amount,
                block_number: current_block,
                timestamp: current_timestamp,
            });

            // Return game_id, whether player won, and payout amount
            (game_id, player_won, payout_amount)
        }
    }
} 