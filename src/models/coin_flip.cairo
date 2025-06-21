use starknet::ContractAddress;

// Enum for coin flip sides
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum CoinSide {
    Heads,
    Tails,
}

impl CoinSideIntoFelt252 of Into<CoinSide, felt252> {
    fn into(self: CoinSide) -> felt252 {
        match self {
            CoinSide::Heads => 1,
            CoinSide::Tails => 2,
        }
    }
}

impl OptionCoinSideIntoFelt252 of Into<Option<CoinSide>, felt252> {
    fn into(self: Option<CoinSide>) -> felt252 {
        match self {
            Option::None => 0,
            Option::Some(c) => c.into(),
        }
    }
}

// Enum for game status - enforces two-transaction flow
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameStatus {
    Pending, // Bet locked, waiting for VRF resolution (must be next block)
    Completed, // VRF resolved, game finished
    Expired // Game expired without resolution
}

impl GameStatusIntoFelt252 of Into<GameStatus, felt252> {
    fn into(self: GameStatus) -> felt252 {
        match self {
            GameStatus::Pending => 0,
            GameStatus::Completed => 1,
            GameStatus::Expired => 2,
        }
    }
}

// Main coin flip game model
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct CoinFlipGame {
    #[key]
    pub game_id: u32,
    #[key]
    pub player: ContractAddress,
    pub bet_amount: u256, // Amount in STRK tokens (locked)
    pub chosen_side: Option<CoinSide>, // Player's choice (Heads/Tails) - set when bet is placed
    pub actual_result: Option<CoinSide>, // Actual coin flip result (set in tx2)
    pub status: GameStatus, // Game status
    pub house_edge_basis_points: u16, // House edge used for this game
    pub payout_amount: u256, // Payout amount (calculated in tx2)
    pub bet_block_number: u64, // Block when bet was placed (tx1)
    pub resolve_block_number: u64, // Block when game was resolved (tx2)
    pub timestamp: u64 // Game creation timestamp
}

// Traits for the coin flip game
pub trait CoinFlipGameTrait {
    fn is_pending(self: CoinFlipGame) -> bool;
    fn is_completed(self: CoinFlipGame) -> bool;
    fn is_expired(self: CoinFlipGame, current_block: u64, expiry_blocks: u64) -> bool;
    fn can_resolve(self: CoinFlipGame, current_block: u64) -> bool;
    fn must_wait_next_block(self: CoinFlipGame, current_block: u64) -> bool;
    fn calculate_payout(bet_amount: u256, house_edge_bp: u16) -> u256;
    fn did_player_win(self: CoinFlipGame) -> bool;
}

impl CoinFlipGameImpl of CoinFlipGameTrait {
    fn is_pending(self: CoinFlipGame) -> bool {
        self.status == GameStatus::Pending
    }

    fn is_completed(self: CoinFlipGame) -> bool {
        self.status == GameStatus::Completed
    }

    fn is_expired(self: CoinFlipGame, current_block: u64, expiry_blocks: u64) -> bool {
        self.is_pending() && current_block > self.bet_block_number + expiry_blocks
    }

    fn can_resolve(self: CoinFlipGame, current_block: u64) -> bool {
        // Can only resolve if game is pending and at least 1 block has passed
        self.is_pending() && current_block > self.bet_block_number
    }

    fn must_wait_next_block(self: CoinFlipGame, current_block: u64) -> bool {
        // Enforce that resolution must happen in a different block than bet
        self.is_pending() && current_block <= self.bet_block_number
    }

    fn calculate_payout(bet_amount: u256, house_edge_bp: u16) -> u256 {
        // Calculate payout for winning bet based on house edge
        // Standard 2x payout adjusted for house edge
        let house_edge_multiplier = 10000_u256 - house_edge_bp.into();
        (bet_amount * 20000_u256) / house_edge_multiplier
    }

    fn did_player_win(self: CoinFlipGame) -> bool {
        match (self.chosen_side, self.actual_result) {
            (Option::Some(chosen), Option::Some(actual)) => chosen == actual,
            _ => false,
        }
    }
}

// Constants for game flow
pub const MAX_BLOCKS_TO_RESOLVE: u64 = 10; // Game expires if not resolved within 10 blocks
