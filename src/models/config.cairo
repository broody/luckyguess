#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Config {
    #[key]
    pub world_resource: felt252, // Use a constant key like 'GAME_CONFIG'
    pub house_edge_basis_points: u16,    // House edge (e.g., 250 = 2.5%)
    pub min_bet_amount: u32,             // Minimum bet amount (no decimals)
    pub max_bet_amount: u32,             // Maximum bet amount (no decimals)
    pub max_blocks_to_resolve: u64,      // Game expiry in blocks
    pub is_paused: bool,                 // Emergency pause mechanism
}

// Trait for config management
pub trait ConfigTrait {
    fn default() -> Config;
    fn is_valid_bet_amount(self: Config, amount: u32) -> bool;
    fn is_game_paused(self: Config) -> bool;
    fn calculate_payout(self: Config, bet_amount: u32) -> u32;
}

pub impl ConfigImpl of ConfigTrait {
    fn default() -> Config {
        Config {
            world_resource: WORLD_RESOURCE,
            house_edge_basis_points: 250,        // 2.5% house edge
            min_bet_amount: 1,                    // 1 token minimum
            max_bet_amount: 1000,                 // 1000 tokens maximum
            max_blocks_to_resolve: 10,            // 10 blocks to resolve
            is_paused: false,
        }
    }

    fn is_valid_bet_amount(self: Config, amount: u32) -> bool {
        amount >= self.min_bet_amount && amount <= self.max_bet_amount
    }

    fn is_game_paused(self: Config) -> bool {
        self.is_paused
    }

    fn calculate_payout(self: Config, bet_amount: u32) -> u32 {
        // Calculate payout for winning bet based on house edge
        // Standard 2x payout adjusted for house edge
        let house_edge_multiplier = 10000_u32 - self.house_edge_basis_points.into();
        let bet_amount_u32: u32 = bet_amount;
        (bet_amount_u32 * 20000_u32) / house_edge_multiplier
    }
}

pub const WORLD_RESOURCE: felt252 = 0;