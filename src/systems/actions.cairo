use luckyguess::models::coin_flip::CoinSide;

// Interface definition
#[starknet::interface]
pub trait IActions<T> {
    fn place_bet(ref self: T, bet_amount: u256, chosen_side: CoinSide) -> u32;
    fn resolve_bet(ref self: T, game_id: u32);
}

#[dojo::contract]
mod actions {
    use starknet::{ContractAddress, get_caller_address, get_block_info};
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo::world::IWorldDispatcherTrait;

    use luckyguess::models::coin_flip::{
        CoinFlipGame, CoinSide, GameStatus, CoinFlipGameTrait, MAX_BLOCKS_TO_RESOLVE,
    };
    use luckyguess::random::RandomImpl;

    #[derive(Drop, Serde)]
    #[dojo::event]
    struct BetPlaced {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        bet_amount: u256,
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
        payout_amount: u256,
        block_number: u64,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of super::IActions<ContractState> {
        fn place_bet(ref self: ContractState, bet_amount: u256, chosen_side: CoinSide) -> u32 {
            let player = get_caller_address();
            let block_info = get_block_info().unbox();
            let current_block = block_info.block_number;
            let current_timestamp = block_info.block_timestamp;
            let mut world = self.world(@"luckyguess");

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
                house_edge_basis_points: 250, // 2.5% house edge
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

            // Get the game
            let mut game: CoinFlipGame = world.read_model((game_id, player));

            // Validate game can be resolved
            assert(game.status == GameStatus::Pending, 'Game not pending');
            assert(game.bet_amount > 0, 'No bet placed');
            assert(game.chosen_side.is_some(), 'No side chosen');
            assert(game.can_resolve(current_block), 'Must wait for next block');
            assert(!game.is_expired(current_block, MAX_BLOCKS_TO_RESOLVE), 'Game expired');

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
                CoinFlipGameTrait::calculate_payout(game.bet_amount, game.house_edge_basis_points)
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
    }
}
