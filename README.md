# Space Shooter

A retro-style arcade space shooting game built with **Flutter** and **Flame Engine**.

> **Built with AI**: This game was developed using [self-evolving-agent](https://github.com/miles990/self-evolving-agent)'s `/evolve` skill - an autonomous AI agent that learns and iterates until goals are achieved.

## Play Now

[Play Space Shooter](https://miles990.github.io/flame_demo_game/)

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

## How This Game Was Built

This project demonstrates **AI-assisted game development** using the self-evolving-agent workflow:

### Step 1: Create Domain Skill
First, a [Flame Engine skill](https://github.com/miles990/self-evolving-agent/blob/main/skills/flame-game-dev/SKILL.md) was created based on the [Flame Engine documentation](https://github.com/flame-engine/flame). This skill encapsulates:
- Flame architecture patterns (FlameGame, Components, World/Camera)
- Input handling (keyboard, touch, joystick)
- Collision detection system
- Sprite animation patterns
- Audio integration
- Common game patterns (object pooling, spawners, parallax)

### Step 2: Evolve the Game
With the Flame skill in place, the `/evolve` command was used to iteratively build the game:

```bash
/evolve 建立一個太空射擊遊戲
/evolve 加入武器升級和道具掉落系統
/evolve 加入多種敵人類型和 Boss
/evolve 部署到 GitHub Pages
```

The self-evolving-agent autonomously:
- Searched memory for relevant patterns
- Applied Flame Engine best practices from the skill
- Implemented features with proper architecture
- Tested and fixed issues iteratively
- Deployed the final product

### Why This Approach?

| Traditional | AI-Assisted |
|-------------|-------------|
| Read docs → Write code → Debug | Skill captures expertise → AI applies patterns |
| Manual iteration | Autonomous PDCA cycles |
| Knowledge in developer's head | Knowledge encoded in reusable skills |

**Skills are "packaged judgment"** - they tell AI when to use what patterns, reducing decision points and ensuring consistency.

## Tech Stack

- **Flutter** 3.x
- **Flame Engine** 1.x
- **Dart** 3.x
- **AI Agent**: [self-evolving-agent](https://github.com/miles990/self-evolving-agent)

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

- Built with [Flame Engine](https://flame-engine.org/) - A minimalist 2D game engine for Flutter
- Developed using [self-evolving-agent](https://github.com/miles990/self-evolving-agent) - An autonomous AI development workflow
