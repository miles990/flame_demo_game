# Space Shooter

A retro-style arcade space shooting game built with **Flutter** and **Flame Engine**.

## Play Now

[Play Space Shooter](https://user.github.io/flame_demo_game/)

## Screenshots

```
   ╔══════════════════════════════════════╗
   ║  SCORE: 12500          WAVE 3    ❤❤❤ ║
   ║                                      ║
   ║         ◆      ★                     ║
   ║    ▼         ●         ■             ║
   ║                                      ║
   ║              ▲                       ║
   ║             /|\                      ║
   ║              🔥                       ║
   ╚══════════════════════════════════════╝
```

## Features

### Weapon System (4 Levels)
| Level | Pattern |
|-------|---------|
| Lv1 | Single shot |
| Lv2 | Dual parallel shots |
| Lv3 | Triple spread |
| Lv4 | Quintuple spread |

### Power-ups (6 Types)
| Item | Color | Effect | Drop Rate |
|------|-------|--------|-----------|
| Weapon Upgrade (W) | Orange | Level up weapon | 35% |
| Shield (S) | Blue | 8s protection | 20% |
| Rapid Fire (R) | Purple | 5s double fire rate | 15% |
| Speed Boost (>) | Yellow | 6s faster movement | 15% |
| Bomb (B) | Red | Clear all enemies | 10% |
| Extra Life (+) | Green | +1 life | 5% |

### Enemy Types (5 Types)
| Type | Shape | Behavior |
|------|-------|----------|
| Basic | Hexagon (Red) | Sine wave movement |
| Fast | Triangle (Orange) | High-speed straight |
| Tank | Square (Gray) | Slow but 3 HP |
| Shooter | Diamond (Purple) | Fires bullets |
| Zigzag | Star (Cyan) | Side-to-side movement |

### Boss Battles
- Appears every 5 waves
- Multiple attack patterns (spread, triple, circular)
- Drops 3 random power-ups on defeat
- Health scales with stage

## Controls

| Key | Action |
|-----|--------|
| ↑↓←→ / WASD | Move |
| SPACE | Shoot |
| ESC | Pause |

## Tech Stack

- **Flutter** 3.x
- **Flame Engine** 1.x
- **Dart** 3.x

## Development

```bash
# Install dependencies
flutter pub get

# Run in development
flutter run -d chrome

# Build for production
flutter build web --release
```

## Deployment

The game is deployed to GitHub Pages using the `gh-pages` branch.

```bash
# Build and deploy
flutter build web --release
# Copy build/web/* to gh-pages branch
```

## License

MIT License

## Credits

Built with [Flame Engine](https://flame-engine.org/) - A minimalist 2D game engine for Flutter.
