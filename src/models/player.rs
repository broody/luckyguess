use starknet::ContractAddress;

// Player statistics model
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerStats {
    #[key]
    pub player: ContractAddress,
    pub total_games: u32,
    pub games_won: u32,
    pub games_lost: u32,
    pub total_bet_amount: u256,        // Total STRK bet
    pub total_winnings: u256,          // Total STRK won
    pub total_losses: u256,            // Total STRK lost
    pub guess_tokens_earned: u256,     // Total GUESS tokens earned
    pub current_streak: u32,           // Current win/loss streak
    pub best_streak: u32,              // Best winning streak
}

// Player balance model for token management
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerBalance {
    #[key]
    pub player: ContractAddress,
    pub strk_balance: u256,            // Available STRK for betting
    pub guess_balance: u256,           // Available GUESS tokens
    pub locked_strk: u256,             // STRK locked in pending games
}

// House edge modifier model - tracks basis point purchases
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct HouseEdgeModifier {
    #[key]
    pub player: ContractAddress,
    pub remaining_modified_bets: u32,  // Number of bets with reduced house edge
    pub basis_points_reduction: u16,   // How much the house edge is reduced
    pub expiry_timestamp: u64,         // When the modifier expires
}

// Traits for player models
trait PlayerStatsImpl {
    fn update_win(ref self: PlayerStats, bet_amount: u256, payout: u256, guess_earned: u256);
    fn update_loss(ref self: PlayerStats, bet_amount: u256);
    fn win_rate(self: PlayerStats) -> u256;
    fn profit_loss(self: PlayerStats) -> i256;
}

impl PlayerStatsTraitImpl of PlayerStatsImpl {
    fn update_win(ref self: PlayerStats, bet_amount: u256, payout: u256, guess_earned: u256) {
        self.total_games += 1;
        self.games_won += 1;
        self.total_bet_amount += bet_amount;
        self.total_winnings += payout;
        self.guess_tokens_earned += guess_earned;
        self.current_streak += 1;
        if self.current_streak > self.best_streak {
            self.best_streak = self.current_streak;
        }
    }

    fn update_loss(ref self: PlayerStats, bet_amount: u256) {
        self.total_games += 1;
        self.games_lost += 1;
        self.total_bet_amount += bet_amount;
        self.total_losses += bet_amount;
        self.current_streak = 0;
    }

    fn win_rate(self: PlayerStats) -> u256 {
        if self.total_games == 0 {
            return 0;
        }
        (self.games_won.into() * 10000) / self.total_games.into()
    }

    fn profit_loss(self: PlayerStats) -> i256 {
        // Calculate net profit/loss (winnings - total bet amount)
        let winnings: i256 = self.total_winnings.try_into().unwrap();
        let total_bet: i256 = self.total_bet_amount.try_into().unwrap();
        winnings - total_bet
    }
}

trait PlayerBalanceImpl {
    fn can_bet(self: PlayerBalance, amount: u256) -> bool;
    fn lock_funds(ref self: PlayerBalance, amount: u256);
    fn unlock_funds(ref self: PlayerBalance, amount: u256);
    fn add_winnings(ref self: PlayerBalance, amount: u256);
    fn add_guess_tokens(ref self: PlayerBalance, amount: u256);
    fn spend_guess_tokens(ref self: PlayerBalance, amount: u256) -> bool;
}

impl PlayerBalanceTraitImpl of PlayerBalanceImpl {
    fn can_bet(self: PlayerBalance, amount: u256) -> bool {
        self.strk_balance >= amount
    }

    fn lock_funds(ref self: PlayerBalance, amount: u256) {
        assert(self.strk_balance >= amount, 'Insufficient balance');
        self.strk_balance -= amount;
        self.locked_strk += amount;
    }

    fn unlock_funds(ref self: PlayerBalance, amount: u256) {
        assert(self.locked_strk >= amount, 'Insufficient locked funds');
        self.locked_strk -= amount;
        self.strk_balance += amount;
    }

    fn add_winnings(ref self: PlayerBalance, amount: u256) {
        self.strk_balance += amount;
    }

    fn add_guess_tokens(ref self: PlayerBalance, amount: u256) {
        self.guess_balance += amount;
    }

    fn spend_guess_tokens(ref self: PlayerBalance, amount: u256) -> bool {
        if self.guess_balance >= amount {
            self.guess_balance -= amount;
            true
        } else {
            false
        }
    }
}

trait HouseEdgeModifierImpl {
    fn is_active(self: HouseEdgeModifier, current_timestamp: u64) -> bool;
    fn can_apply(self: HouseEdgeModifier, current_timestamp: u64) -> bool;
    fn apply_reduction(ref self: HouseEdgeModifier) -> u16;
}

impl HouseEdgeModifierTraitImpl of HouseEdgeModifierImpl {
    fn is_active(self: HouseEdgeModifier, current_timestamp: u64) -> bool {
        self.remaining_modified_bets > 0 && current_timestamp <= self.expiry_timestamp
    }

    fn can_apply(self: HouseEdgeModifier, current_timestamp: u64) -> bool {
        self.is_active(current_timestamp)
    }

    fn apply_reduction(ref self: HouseEdgeModifier) -> u16 {
        if self.remaining_modified_bets > 0 {
            self.remaining_modified_bets -= 1;
            self.basis_points_reduction
        } else {
            0
        }
    }
} 