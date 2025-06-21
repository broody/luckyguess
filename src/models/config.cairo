#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Config {
    #[key]
    pub world_resource: felt252, // Use a constant key like 'GAME_CONFIG'
    pub house_edge_basis_points: u16,    // House edge (e.g., 250 = 2.5%)
    pub min_bet_amount: u256,             // Minimum bet amount (with decimals)
    pub max_bet_amount: u256,             // Maximum bet amount (with decimals)
    pub max_blocks_to_resolve: u64,       // Game expiry in blocks
    pub is_paused: bool,                  // Emergency pause mechanism
}

// Trait for config management
pub trait ConfigTrait {
    fn default() -> Config;
    fn is_valid_bet_amount(self: Config, amount: u256) -> bool;
    fn is_game_paused(self: Config) -> bool;
    fn calculate_payout(self: Config, bet_amount: u256) -> u256;
}

pub impl ConfigImpl of ConfigTrait {
    fn default() -> Config {
        Config {
            world_resource: WORLD_RESOURCE,
            house_edge_basis_points: 250,        // 2.5% house edge
            min_bet_amount: 1000000000000000000,  // 1 token (18 decimals)
            max_bet_amount: 1000000000000000000000, // 1000 tokens (18 decimals)
            max_blocks_to_resolve: 10,            // 10 blocks to resolve
            is_paused: false,
        }
    }

    fn is_valid_bet_amount(self: Config, amount: u256) -> bool {
        amount >= self.min_bet_amount && amount <= self.max_bet_amount
    }

    fn is_game_paused(self: Config) -> bool {
        self.is_paused
    }

    fn calculate_payout(self: Config, bet_amount: u256) -> u256 {
        // 2x payout reduced by house edge
        // Example: 2.5% house edge means 2x * 0.975 = 1.95x payout
        let house_edge_multiplier = 10000_u256 - self.house_edge_basis_points.into();
        (bet_amount * 2_u256 * house_edge_multiplier) / 10000_u256
    }
}

pub const WORLD_RESOURCE: felt252 = 0;