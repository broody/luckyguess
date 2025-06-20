pub mod coin_flip;
pub mod player;
pub mod config;
pub mod analytics;

// Re-export coin flip models
pub use coin_flip::{
    CoinSide, GameStatus, CoinFlipGame, VRFRequest, CoinFlipGameTrait
};

// Re-export player models
pub use player::{
    PlayerStats, PlayerBalance, HouseEdgeModifier,
    PlayerStatsImpl, PlayerBalanceImpl, HouseEdgeModifierImpl
};

// Re-export config models and constants
pub use config::{
    CoinFlipSettings, GlobalGameSettings, ConfigImpl,
    COIN_FLIP_SETTINGS_ID, GLOBAL_SETTINGS_ID, DEFAULT_HOUSE_EDGE_BP, 
    BASIS_POINT_SCALE, DEFAULT_MIN_BET, DEFAULT_MAX_BET, DEFAULT_GUESS_REWARD_RATE
};

// Re-export analytics models
pub use analytics::{
    GameAnalytics, PlayerLeaderboard, GamePerformance, 
    HouseEdgeAnalytics, VRFAnalytics, AnalyticsImpl, LeaderboardImpl,
    get_daily_timestamp, calculate_win_rate_bp
};
