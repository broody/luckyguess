use starknet::ContractAddress;

// Daily/weekly statistics for analytics
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GameAnalytics {
    #[key]
    pub date: u64,                     // Date in unix timestamp (daily)
    pub total_games: u32,
    pub total_volume: u256,            // Total STRK volume
    pub house_profit: u256,            // House profit for the day
    pub unique_players: u32,
    pub average_bet_size: u256,
    pub total_payouts: u256,           // Total payouts to players
    pub guess_tokens_distributed: u256, // Total GUESS tokens distributed
}

// Player leaderboard for competitive features
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerLeaderboard {
    #[key]
    pub player: ContractAddress,
    pub total_volume: u256,            // Total volume bet by player
    pub net_profit: i256,              // Net profit/loss
    pub rank_by_volume: u32,           // Rank by total volume
    pub rank_by_profit: u32,           // Rank by profit
    pub last_updated: u64,             // Last update timestamp
}

// Game performance metrics
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GamePerformance {
    #[key]
    pub game_type: felt252,            // 'coin_flip', 'roulette', etc.
    #[key]
    pub date: u64,                     // Date in unix timestamp
    pub total_games: u32,
    pub total_volume: u256,
    pub house_edge_achieved: u256,     // Actual house edge achieved (basis points)
    pub player_win_rate: u256,         // Player win rate (basis points)
    pub average_game_duration: u64,    // Average game duration in seconds
}

// House edge effectiveness tracking
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct HouseEdgeAnalytics {
    #[key]
    pub date: u64,
    pub total_basis_points_purchased: u256, // Total basis points purchased by players
    pub total_guess_spent: u256,       // Total GUESS tokens spent on reductions
    pub average_house_edge: u256,      // Average effective house edge
    pub reduction_usage_rate: u256,    // Percentage of games with house edge reduction
}

// VRF performance and reliability tracking
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct VRFAnalytics {
    #[key]
    pub date: u64,
    pub total_vrf_requests: u32,
    pub successful_fulfillments: u32,
    pub failed_fulfillments: u32,
    pub average_fulfillment_time: u64, // Average time to fulfill VRF request
    pub total_vrf_fees: u256,          // Total VRF fees paid
}

// Traits for analytics operations
trait AnalyticsImpl {
    fn update_daily_stats(
        ref self: GameAnalytics, 
        bet_amount: u256, 
        payout: u256, 
        house_profit: u256,
        guess_distributed: u256
    );
    fn calculate_house_edge_percentage(self: GameAnalytics) -> u256;
    fn get_profit_margin(self: GameAnalytics) -> u256;
}

impl AnalyticsTraitImpl of AnalyticsImpl {
    fn update_daily_stats(
        ref self: GameAnalytics, 
        bet_amount: u256, 
        payout: u256, 
        house_profit: u256,
        guess_distributed: u256
    ) {
        self.total_games += 1;
        self.total_volume += bet_amount;
        self.house_profit += house_profit;
        self.total_payouts += payout;
        self.guess_tokens_distributed += guess_distributed;
        
        // Recalculate average bet size
        self.average_bet_size = self.total_volume / self.total_games.into();
    }

    fn calculate_house_edge_percentage(self: GameAnalytics) -> u256 {
        if self.total_volume == 0 {
            return 0;
        }
        (self.house_profit * 10000) / self.total_volume
    }

    fn get_profit_margin(self: GameAnalytics) -> u256 {
        if self.total_volume == 0 {
            return 0;
        }
        let net_profit = self.total_volume - self.total_payouts;
        (net_profit * 10000) / self.total_volume
    }
}

trait LeaderboardImpl {
    fn update_player_stats(
        ref self: PlayerLeaderboard, 
        volume_delta: u256, 
        profit_delta: i256,
        current_timestamp: u64
    );
}

impl LeaderboardTraitImpl of LeaderboardImpl {
    fn update_player_stats(
        ref self: PlayerLeaderboard, 
        volume_delta: u256, 
        profit_delta: i256,
        current_timestamp: u64
    ) {
        self.total_volume += volume_delta;
        self.net_profit += profit_delta;
        self.last_updated = current_timestamp;
        // Note: Rank calculations would be done by the system when querying
    }
}

// Utility functions for analytics
pub fn get_daily_timestamp(timestamp: u64) -> u64 {
    // Convert timestamp to daily bucket (midnight UTC)
    timestamp / 86400 * 86400
}

pub fn calculate_win_rate_bp(wins: u32, total: u32) -> u256 {
    if total == 0 {
        return 0;
    }
    (wins.into() * 10000) / total.into()
} 