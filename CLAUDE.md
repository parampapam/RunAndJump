# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**RunAndJump** — 2D iOS platformer built with Swift and SpriteKit. Landscape orientation, multiple levels, enemies, pickups, portal exit.

## Commands

```bash
# Build
xcodebuild build -scheme RunAndJump -destination "platform=iOS Simulator,name=iPhone 17"

# Run all tests
xcodebuild test -scheme RunAndJump -destination "platform=iOS Simulator,name=iPhone 17"

# Run a single test file (Swift Testing)
xcodebuild test -scheme RunAndJump -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:RunAndJumpTests/GameRulesTests
```

## Architecture

The codebase is split into two clearly separated layers:

### Model layer (`RunAndJump/Model/`, `Levels/`) — pure Swift, no SpriteKit

All game logic lives here as value types (structs/enums) with pure functions. This is what the unit tests cover.

- **`GameRules`** — static functions that apply events to `PlayerState` and return outcomes. Events: `enemyHit`, `healthPickup`, `bonusPickup(points)`, `reachedPortal`.
- **`GameProgress` / `GameProgressRules`** — tracks current level index and accumulated bonus across levels.
- **`JumpController`** — manages coyote time (0.1 s after leaving ground) and jump buffering (0.1 s input window before landing). Call `didTouchGround`, `didLeaveGround`, `didPressJump`, then `consumeJumpIfPossible`.
- **`LevelConfiguration`** — declarative struct defining scene size, player start, ground, enemies, pickups, and portal positions for a level. No SpriteKit types here.
- **`Levels` enum** — hardcodes the three levels as `LevelConfiguration` values.
- **`PhysicsCategory`** — bitmask constants for SpriteKit physics contacts.

### Scene / Node layer (`Scenes/`, `Nodes/`, `Movement/`) — SpriteKit

- **`GameScene`** — main SKScene. Initialises from `LevelConfiguration` via `LevelBuilder`, runs the game loop in `update()`, handles `SKPhysicsContactDelegate`, and drives state transitions (playing → died → restart or completed → next level via `GameProgress`).
- **`VictoryScene`** — shown after all levels complete; displays total bonus.
- **`Player`** — moves at 250 pts/s horizontally; jump impulse 120. Reads commands from `InputController`.
- **`Enemy`** / `LevelObject` — SpriteKit node with an injected `EnemyMovement` strategy (`StationaryMovement`, `PatrollingMovement`). Enemies and pickups are non-dynamic; their positions are updated manually each frame.
- **`Pickup`** — green = health, yellow = bonus points.
- **`Portal`** — level exit (purple).
- **`HUDNode`** — overlays health and bonus points.
- **`InputController`** — touch-based left/right/jump buttons; tracks per-touch events to detect button release.
- **`LevelBuilder`** — factory that creates SpriteKit nodes from descriptor structs in `LevelConfiguration`.

### Testing

Uses **Swift Testing** (`@Test` macros, not XCTest). Tests are in `RunAndJumpTests/` and cover only the model layer:
- `GameRulesTests` — state transitions and outcomes
- `JumpControllerTests` — coyote time, jump buffering, double-jump prevention
- `GameProgressTests` — level advancement and bonus carryover
