![Dojo Starter](./assets/cover.png)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/mark-dark.svg">
  <img alt="Dojo logo" align="right" width="120" src=".github/mark-light.svg">
</picture>

<a href="https://x.com/ohayo_dojo">
<img src="https://img.shields.io/twitter/follow/dojostarknet?style=social"/>
</a>
<a href="https://github.com/dojoengine/dojo/stargazers">
<img src="https://img.shields.io/github/stars/dojoengine/dojo?style=social"/>
</a>

[![discord](https://img.shields.io/badge/join-dojo-green?logo=discord&logoColor=white)](https://discord.com/invite/dojoengine)
[![Telegram Chat][tg-badge]][tg-url]

[tg-badge]: https://img.shields.io/endpoint?color=neon&logo=telegram&label=chat&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fdojoengine
[tg-url]: https://t.me/dojoengine

# Lucky Guess 🎲

An onchain gambling platform featuring provably fair games powered by VRF.

## Overview

Lucky Guess is a collection of simple betting games deployed on Starknet. Currently features:

- **Coin Flip** 🪙 - Bet on heads or tails with single-transaction gameplay
- **Configurable House Edge** - Transparent payout-based advantage system  
- **VRF Integration** - Provably fair randomness via Verifiable Random Functions
- **Admin Controls** - Comprehensive configuration and emergency pause system

## Quick Start

### Prerequisites
- Dojo v1.5.0
- Scarb with Cairo 2.10.1

### Running Locally

#### Terminal 1 - Start Katana
```bash
katana --dev --dev.no-fee --http.cors_origins "*"
```

#### Terminal 2 - Deploy & Run
```bash
# Build contracts
sozo build

# Deploy to local Katana
sozo migrate

# Start indexer (replace <WORLD_ADDRESS> with deployed world address)
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

### Using Docker
```bash
docker compose up
```

## Game Mechanics

### Coin Flip
```cairo
// Single transaction gameplay
let (game_id, won, payout) = game_actions.flip_coin(bet_amount, CoinSide::Heads);
```

- **Betting**: Use STRK tokens with 18 decimal precision
- **House Edge**: 2.5% default (configurable by admin)
- **Randomness**: VRF-powered for provable fairness
- **Payouts**: Instant settlement in same transaction

### Configuration Management
```cairo
// Admin functions
config_actions.set_house_edge(250);        // 2.5% house edge
config_actions.set_bet_limits(min, max);   // Configure bet limits
config_actions.pause_game();               // Emergency pause
config_actions.set_use_vrf(true);          // Enable VRF
```

## Architecture

## Key Features

- ✅ **Single-Transaction Games** - No waiting between bet and resolution
- ✅ **VRF Integration** - Cryptographically secure randomness
- ✅ **Transparent House Edge** - Payout-based, not probability manipulation
- ✅ **Admin Controls** - Granular configuration management
- ✅ **Emergency Pause** - Instant game suspension capability
- ✅ **Event Logging** - Complete audit trail
- 🚧 **Token Integration** - STRK betting, GUESS rewards (coming soon)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-game`
3. Commit changes: `git commit -am 'Add new game'`
4. Push to branch: `git push origin feature/new-game`
5. Submit a Pull Request

## Resources

- **Website**: [luckyguess.gg](https://luckyguess.gg)
- **Dojo Docs**: [book.dojoengine.org](https://book.dojoengine.org)
- **Cairo Docs**: [book.cairo-lang.org](https://book.cairo-lang.org)

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

Built with ❤️ using [Dojo Engine](https://dojoengine.org)
