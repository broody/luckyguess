# Lucky Guess - Onchain Gambling Game

## Project Overview

**Lucky Guess** is a collection of simple onchain betting games built on the Dojo engine, leveraging Verifiable Random Functions (VRF) for provably fair gameplay. The platform is hosted at [luckyguess.gg](https://luckyguess.gg) and features multiple gambling games with a house edge system and player reward mechanisms.

## Technical Stack

- **Framework**: Dojo Engine v1.5.0
- **Language**: Cairo 2.10.1
- **Blockchain**: Starknet
- **Randomness**: VRF (Verifiable Random Function) + Pedersen Hash fallback
- **Primary Token**: STRK (betting currency)
- **Reward Token**: GUESS (earned through gameplay)

## Game Portfolio

### 1. Coin Flip 🪙 [IMPLEMENTED]
- **Concept**: Players bet on heads or tails in a single transaction
- **Betting Token**: STRK (with 18 decimal precision)
- **House Edge**: Payout-based system (e.g., 2.5% default means 1.95x payout instead of 2x)
- **Mechanics**: 
  - Single transaction gameplay using VRF for true randomness
  - Configurable bet limits (default: 1-1000 tokens)
  - Immediate results and payouts
  - Game history stored on-chain

### 2. Roulette 🎰
- **Concept**: Traditional roulette game
- **Status**: Planned
- **House Edge**: Will follow similar payout-based model

### 3. High-Low Number Guessing 🔢
- **Concept**: Players guess if next number will be higher or lower
- **Status**: Planned
- **House Edge**: Will follow similar payout-based model

### Future Games
- Additional games to be added based on player feedback and market demand
- Each game will maintain the house edge system for long-term profitability

## Tokenomics

### STRK (Betting Currency)
- Primary currency for placing bets across all games
- Standard Starknet token integration with 18 decimal precision
- Direct betting and payout mechanism via token transfers

### GUESS Token (Reward & Utility)
- **Earning**: Players earn GUESS tokens by playing games
- **Utility**: Purchase basis points to reduce house advantage
- **Mechanics**: 
  - Players can spend GUESS tokens to buy basis points
  - Basis points reduce house advantage for a specific number of bets
  - Creates a strategic layer where skilled/frequent players can improve their odds

## House Edge System

### Payout-Based House Edge (Current Implementation)
- **Method**: Reduces payout multipliers rather than manipulating probability
- **Coin Flip**: True 50/50 probability, but winners receive ~1.95x payout (with 2.5% house edge) instead of 2x
- **Benefits**: 
  - Maintains truly fair randomness
  - Transparent and auditable
  - Industry standard approach
  - Player trust through verifiable fairness

### Example Calculation

## Architecture Components

### Smart Contracts (Cairo/Dojo)
```
src/
├── lib.cairo                 # Main library
├── models/
│   ├── coin_flip.rs         # Coin flip game model
│   └── mod.rs               # Models module
├── systems/
│   └── actions.cairo        # Game actions and logic
└── tests/
    └── test_world.cairo     # Test suite
```

### Key Models
- **Player**: User account, balance, statistics
- **Game Session**: Individual game instances
- **Bet**: Bet amount, game type, outcome prediction
- **Token Balance**: STRK and GUESS token management
- **House Edge Modifier**: Basis point purchases and applications

### Key Systems
- **Betting System**: Handle bet placement and validation
- **VRF Integration**: Secure random number generation
- **Payout System**: Calculate and distribute winnings
- **Token Rewards**: GUESS token distribution logic
- **House Edge Management**: Apply and track advantage modifications

## Development Guidelines

### Game Addition Process
1. Define game rules and probability mechanics
2. Calculate appropriate house edge percentage
3. Implement game model in Cairo
4. Add game logic to actions system
5. Integrate with VRF for randomness
6. Add comprehensive tests
7. Update frontend interface

### Testing Strategy
- Unit tests for each game type
- Integration tests for token interactions
- VRF randomness validation
- House edge probability verification
- End-to-end gameplay testing

### Deployment Configuration
- **Development**: `dojo_dev.toml`
- **Production**: `dojo_release.toml`
- **Torii**: `torii_dev.toml` for indexing

## Business Model

### Revenue Streams
1. **House Edge**: Guaranteed profit from probability advantage
2. **Transaction Fees**: Small fees on bet placement (optional)
3. **Premium Features**: Enhanced GUESS token utilities

### Player Incentives
1. **GUESS Token Rewards**: Earned through gameplay
2. **House Edge Reduction**: Strategic advantage for frequent players
3. **Progressive Features**: Unlockable content and games

## Security Considerations

### Smart Contract Security
- Comprehensive testing of all game logic
- VRF integration validation
- Reentrancy protection
- Access control for administrative functions

### Fairness Guarantees
- VRF ensures provably fair randomness
- On-chain verification of all game outcomes
- Transparent house edge calculations
- Public audit trail of all bets and payouts

## Future Roadmap

### Phase 1: Core Games
- [x] Project setup and architecture
- [ ] Coin flip implementation
- [ ] VRF integration
- [ ] Basic GUESS token system

### Phase 2: Game Expansion
- [ ] Roulette game
- [ ] High-low number guessing
- [ ] Advanced GUESS token utilities

### Phase 3: Platform Features
- [ ] Player statistics and leaderboards
- [ ] Social features and referrals
- [ ] Mobile-optimized interface
- [ ] Additional token integrations

## Contact & Resources

- **Website**: [luckyguess.gg](https://luckyguess.gg)
- **Repository**: Current workspace
- **Documentation**: This file and inline code comments
- **Dojo Documentation**: [Dojo Engine Docs](https://book.dojoengine.org/)

---

*This document serves as the primary reference for Lucky Guess development. Update regularly as features are implemented and requirements evolve.* 