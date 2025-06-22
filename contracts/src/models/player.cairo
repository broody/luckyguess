use starknet::ContractAddress;

// Player statistics model for coin flip games
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct CoinFlipPlayerStats {
    #[key]
    pub player: ContractAddress,
    pub total_games: u32,              // Total games played
    pub wins: u32,                     // Total wins
    pub losses: u32,                   // Total losses
    pub total_wagered: u256,           // Total amount wagered across all games
    pub total_winnings: u256,          // Total winnings (including original bets)
    pub total_losses_amount: u256,     // Total amount lost
    pub current_win_streak: u32,       // Current consecutive wins
    pub current_lose_streak: u32,      // Current consecutive losses
    pub highest_win_streak: u32,       // All-time highest win streak
    pub highest_lose_streak: u32,      // All-time highest lose streak
    pub biggest_win: u256,             // Largest single game payout
    pub biggest_loss: u256,            // Largest single game loss
    pub average_bet_size: u256,        // Average bet amount
    pub last_game_timestamp: u64,      // When they last played
}

// Trait for player statistics management
pub trait CoinFlipPlayerStatsTrait {
    fn new(player: ContractAddress) -> CoinFlipPlayerStats;
    fn update_after_game(
        ref self: CoinFlipPlayerStats, 
        bet_amount: u256, 
        payout_amount: u256, 
        won: bool,
        timestamp: u64
    );
    fn get_win_rate(self: CoinFlipPlayerStats) -> u32; // Returns win rate in basis points
    fn get_current_streak_type(self: CoinFlipPlayerStats) -> StreakType;
}

#[derive(Copy, Drop, Serde, Debug, PartialEq)]
pub enum StreakType {
    WinStreak,
    LoseStreak,
    None,
}

impl CoinFlipPlayerStatsImpl of CoinFlipPlayerStatsTrait {
    fn new(player: ContractAddress) -> CoinFlipPlayerStats {
        CoinFlipPlayerStats {
            player,
            total_games: 0,
            wins: 0,
            losses: 0,
            total_wagered: 0,
            total_winnings: 0,
            total_losses_amount: 0,
            current_win_streak: 0,
            current_lose_streak: 0,
            highest_win_streak: 0,
            highest_lose_streak: 0,
            biggest_win: 0,
            biggest_loss: 0,
            average_bet_size: 0,
            last_game_timestamp: 0,
        }
    }

    fn update_after_game(
        ref self: CoinFlipPlayerStats, 
        bet_amount: u256, 
        payout_amount: u256, 
        won: bool,
        timestamp: u64
    ) {
        // Update basic counters
        self.total_games += 1;
        self.total_wagered += bet_amount;
        self.last_game_timestamp = timestamp;

        if won {
            // Player won
            self.wins += 1;
            self.total_winnings += payout_amount;

            // Update win streak
            self.current_win_streak += 1;
            self.current_lose_streak = 0;
            
            // Check if new record win streak
            if self.current_win_streak > self.highest_win_streak {
                self.highest_win_streak = self.current_win_streak;
            }

            // Check if biggest win
            let net_win = payout_amount - bet_amount;
            if net_win > self.biggest_win {
                self.biggest_win = net_win;
            }
        } else {
            // Player lost
            self.losses += 1;
            self.total_losses_amount += bet_amount;

            // Update lose streak
            self.current_lose_streak += 1;
            self.current_win_streak = 0;
            
            // Check if new record lose streak
            if self.current_lose_streak > self.highest_lose_streak {
                self.highest_lose_streak = self.current_lose_streak;
            }

            // Check if biggest loss
            if bet_amount > self.biggest_loss {
                self.biggest_loss = bet_amount;
            }
        }

        // Update average bet size
        self.average_bet_size = self.total_wagered / self.total_games.into();
    }

    fn get_win_rate(self: CoinFlipPlayerStats) -> u32 {
        // Returns win rate in basis points (e.g., 5000 = 50%)
        if self.total_games == 0 {
            return 0;
        }
        (self.wins.into() * 10000_u256 / self.total_games.into()).try_into().unwrap()
    }

    fn get_current_streak_type(self: CoinFlipPlayerStats) -> StreakType {
        if self.current_win_streak > 0 {
            StreakType::WinStreak
        } else if self.current_lose_streak > 0 {
            StreakType::LoseStreak
        } else {
            StreakType::None
        }
    }
}

// Helper trait for formatting display values
pub trait PlayerStatsDisplay {
    fn format_win_rate(self: CoinFlipPlayerStats) -> (u32, u32); // Returns (whole, decimal) e.g., (47, 50) for 47.50%
}

impl PlayerStatsDisplayImpl of PlayerStatsDisplay {
    fn format_win_rate(self: CoinFlipPlayerStats) -> (u32, u32) {
        let win_rate_bp = self.get_win_rate();
        let whole = win_rate_bp / 100;
        let decimal = win_rate_bp % 100;
        (whole, decimal)
    }
} 