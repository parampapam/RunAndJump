# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**RunAndJump** — 2D iOS platformer built with Swift and SpriteKit. Landscape orientation, multiple levels, enemies, pickups, portal exit.

- Minimum iOS: **iOS 18**
- Swift: **Swift 6**
- Default simulator: **iPhone 17**
- Default scheme: **RunAndJump**

## Build & Test — ALWAYS use XcodeBuildMCP

**Never** invoke raw `xcodebuild` through Bash. XcodeBuildMCP is connected
(dynamic tools mode) and returns structured JSON with categorised errors.

Discover the right tool for the task via the server's discovery mechanism,
then use it. Project parameters:

- Scheme: `RunAndJump`
- Simulator: `iPhone 17`
- Project type: `.xcodeproj` (not workspace)
- Test framework: Swift Testing

Typical workflows:
- **Build**: ask XcodeBuildMCP for a build tool for an iOS Simulator
  xcodeproj by simulator name
- **All tests**: same, but a test tool
- **Single suite**: same test tool with `-only-testing:RunAndJumpTests/<SuiteName>`
- **List schemes / simulators**: discovery / list tools from the server

Fallback for CI only (never in a Claude Code session):

\`\`\`bash
xcodebuild build -scheme RunAndJump -destination "platform=iOS Simulator,name=iPhone 17"
xcodebuild test  -scheme RunAndJump -destination "platform=iOS Simulator,name=iPhone 17"
\`\`\`

## Architecture

The codebase is split into two clearly separated layers. **This separation is load-bearing — never blur it.**

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

## Testing

Uses **Swift Testing** (`@Test` macros, `#expect`, `#require` — not XCTest). Tests are in `RunAndJumpTests/` and cover **only the model layer**:

- `GameRulesTests` — state transitions and outcomes
- `JumpControllerTests` — coyote time, jump buffering, double-jump prevention
- `GameProgressTests` — level advancement and bonus carryover

When adding new game logic, the test for it goes in the model layer too. If something feels untestable, it probably has a SpriteKit dependency that needs to be extracted into a pure type first.

## Working Style

- Proactively suggest architecture improvements: point out when code could be more testable, when responsibilities are mixed, when a value type would fit better than a class, when a dependency should be injected.
- Prefer clarity over cleverness. Explain *why* a design choice helps, not just *what* to change.
- When reviewing code, flag tight coupling, hidden state, and untestable side effects even if I didn't ask.
- When writing new code, default to pure functions and value types where the language allows; isolate I/O and framework dependencies at the edges.

## Conventions & Constraints

**Layer hygiene**
- Never add `import SpriteKit` (or any SK type) to files under `Model/` or `Levels/`. If you need a position, use `CGPoint` from CoreGraphics, not an `SKNode`.
- New gameplay logic → pure functions / value types in `Model/`, covered by a Swift Testing test.

**Extension points**
- New enemy behaviour → implement `EnemyMovement`, don't subclass `Enemy`.
- New level → add a `LevelConfiguration` to the `Levels` enum, don't create a new SKScene subclass.
- New pickup type → extend the existing `Pickup` mechanism rather than introducing a parallel node.

**Project file**
- Do not edit `.pbxproj` by hand — add new files through Xcode. If a new file must be referenced, stop and tell me; don't try to patch the project file.

**Style**
- Swift Testing for all new tests (`@Test`, `#expect`), never XCTest.
- Value types (struct/enum) by default in the model layer; classes only where SpriteKit requires reference semantics.
- Keep the game loop in `update()` ordered: input → player movement → enemy movement → contact resolution → HUD.
