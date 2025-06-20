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
            CoinSide::Heads => 0,
            CoinSide::Tails => 1,
        }
    }
}

// Main coin flip game model - represents a completed game
#[derive(Drop, Serde)]
#[dojo::model]
pub struct CoinFlipGame {
    #[key]
    pub game_id: u32,
    pub player: ContractAddress,
    pub bet_amount: u256,              // Amount in STRK tokens
    pub chosen_side: CoinSide,         // Player's choice (Heads/Tails)
    pub actual_result: CoinSide,       // Actual coin flip result
    pub house_edge_basis_points: u16,  // House edge used for this game
    pub payout_amount: u256,           // Payout amount (0 if lost)
    pub block_number: u64,             // Block when game was played
    pub vrf_request_id: u256,          // VRF request identifier
    pub timestamp: u64,                // Game timestamp
    pub player_won: bool,              // Whether player won or lost
}

// VRF request tracking model (for debugging/analytics)
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct VRFRequest {
    #[key]
    pub request_id: u256,
    pub game_id: u32,
    pub player: ContractAddress,
    pub block_number: u64,
    pub random_value: u256,            // Random value from VRF
}

// Traits for the coin flip game
trait CoinFlipGameTrait {
    fn did_player_win(self: CoinFlipGame) -> bool;
    fn calculate_payout(bet_amount: u256, house_edge_bp: u16) -> u256;
    fn get_net_result(self: CoinFlipGame) -> i256;
}

impl CoinFlipGameImpl of CoinFlipGameTrait {
    fn did_player_win(self: CoinFlipGame) -> bool {
        self.chosen_side == self.actual_result
    }

    fn calculate_payout(bet_amount: u256, house_edge_bp: u16) -> u256 {
        // Calculate payout for winning bet based on house edge
        // Standard 2x payout adjusted for house edge
        let house_edge_multiplier = 10000_u256 - house_edge_bp.into();
        (bet_amount * 20000_u256) / house_edge_multiplier
    }

    fn get_net_result(self: CoinFlipGame) -> i256 {
        // Calculate net profit/loss for the player
        if self.player_won {
            let payout: i256 = self.payout_amount.try_into().unwrap();
            let bet: i256 = self.bet_amount.try_into().unwrap();
            payout - bet
        } else {
            -(self.bet_amount.try_into().unwrap())
        }
    }
}
