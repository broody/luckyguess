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

// Main coin flip game model - simplified for single transaction
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct CoinFlipGame {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub hash: felt252,
    pub bet_amount: u256,                      // Amount in tokens (with decimals)
    pub chosen_side: CoinSide,                 // Player's choice (Heads/Tails)
    pub actual_result: CoinSide,               // Actual coin flip result
    pub house_edge_basis_points: u16,          // House edge used for this game
    pub payout_amount: u256,                   // Payout amount (0 if lost)
    pub block_number: u64,                     // Block when game was played
    pub timestamp: u64,                        // Game timestamp
}

// Traits for the coin flip game
pub trait CoinFlipGameTrait {
    fn calculate_payout(bet_amount: u256, house_edge_bp: u16) -> u256;
    fn did_player_win(self: CoinFlipGame) -> bool;
}

impl CoinFlipGameImpl of CoinFlipGameTrait {
    fn calculate_payout(bet_amount: u256, house_edge_bp: u16) -> u256 {
        // Calculate payout for winning bet based on house edge
        // 2x payout reduced by house edge percentage
        let house_edge_multiplier = 10000_u256 - house_edge_bp.into();
        (bet_amount * 2_u256 * house_edge_multiplier) / 10000_u256
    }

    fn did_player_win(self: CoinFlipGame) -> bool {
        self.chosen_side == self.actual_result
    }
}
