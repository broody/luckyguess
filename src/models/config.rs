// Game settings model for global configuration
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct CoinFlipSettings {
    #[key]
    pub settings_id: u32,              // Constant identifier
    pub default_house_edge_bp: u16,    // Default house edge in basis points
    pub min_bet_amount: u256,          // Minimum bet amount
    pub max_bet_amount: u256,          // Maximum bet amount
    pub guess_reward_rate: u256,       // GUESS tokens per STRK bet (scaled)
    pub max_house_edge_reduction: u16, // Maximum reduction possible
    pub vrf_fee: u256,                 // Fee for VRF request
    pub game_expiry_blocks: u64,       // Blocks until game expires
}

// Global game configuration for other games (future use)
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GlobalGameSettings {
    #[key]
    pub settings_id: u32,
    pub platform_fee_bp: u16,          // Platform fee in basis points
    pub treasury_address: felt252,     // Treasury contract address
    pub min_guess_token_purchase: u256, // Minimum GUESS tokens to purchase house edge reduction
    pub basis_point_cost: u256,        // Cost in GUESS tokens per basis point reduction
    pub max_modifier_duration: u64,    // Maximum duration for house edge modifiers
    pub is_paused: bool,               // Emergency pause functionality
}

// Trait for configuration management
trait ConfigImpl {
    fn is_valid_bet_amount(self: CoinFlipSettings, amount: u256) -> bool;
    fn calculate_guess_reward(self: CoinFlipSettings, bet_amount: u256) -> u256;
    fn calculate_house_edge(self: CoinFlipSettings, reduction: u16) -> u16;
}

impl ConfigTraitImpl of ConfigImpl {
    fn is_valid_bet_amount(self: CoinFlipSettings, amount: u256) -> bool {
        amount >= self.min_bet_amount && amount <= self.max_bet_amount
    }

    fn calculate_guess_reward(self: CoinFlipSettings, bet_amount: u256) -> u256 {
        (bet_amount * self.guess_reward_rate) / BASIS_POINT_SCALE
    }

    fn calculate_house_edge(self: CoinFlipSettings, reduction: u16) -> u16 {
        if reduction > self.default_house_edge_bp {
            0
        } else {
            self.default_house_edge_bp - reduction
        }
    }
}

// Constants for game settings
pub const COIN_FLIP_SETTINGS_ID: u32 = 1;
pub const GLOBAL_SETTINGS_ID: u32 = 9999999999;
pub const DEFAULT_HOUSE_EDGE_BP: u16 = 500; // 5%
pub const BASIS_POINT_SCALE: u256 = 10000;
pub const DEFAULT_MIN_BET: u256 = 1000000000000000000; // 1 STRK (18 decimals)
pub const DEFAULT_MAX_BET: u256 = 1000000000000000000000; // 1000 STRK
pub const DEFAULT_GUESS_REWARD_RATE: u256 = 100; // 1% of bet amount in GUESS tokens 