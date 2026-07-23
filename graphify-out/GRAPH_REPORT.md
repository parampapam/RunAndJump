# Graph Report - RunAndJump  (2026-07-23)

## Corpus Check
- 101 files · ~24,901 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 575 nodes · 1240 edges · 25 communities
- Extraction: 76% EXTRACTED · 24% INFERRED · 0% AMBIGUOUS · INFERRED: 294 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a5688515`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Equatable
- CoreGraphics
- GameScene
- OscillatingMotion
- Player
- PlayerState
- LadderController
- GameProgress
- PlatformRideController
- InputController
- JumpController
- AnalogStick
- GroundContactTracker
- GamepadInput
- InvulnerabilityController
- CLAUDE.md
- SpriteKit
- PickupKind
- ContentView.swift
- Enemy
- HUDNode
- LevelObject
- Decoration
- Platform
- Portal

## God Nodes (most connected - your core abstractions)
1. `GameScene` - 51 edges
2. `LadderController` - 26 edges
3. `PlayerState` - 24 edges
4. `JumpController` - 23 edges
5. `PlatformRideController` - 23 edges
6. `InputController` - 22 edges
7. `TileCoordinate` - 21 edges
8. `CoreGraphics` - 19 edges
9. `Player` - 19 edges
10. `LadderControllerTests` - 19 edges

## Surprising Connections (you probably didn't know these)
- `ObjectSize` --calls--> `TileSize`  [INFERRED]
  RunAndJump/Levels/ObjectSize.swift → RunAndJump/Model/TileCoordinate.swift
- `GamepadInput` --calls--> `AnalogStick`  [INFERRED]
  RunAndJump/Nodes/GamepadInput.swift → RunAndJump/Model/AnalogStick.swift
- `InputController` --calls--> `AnalogStick`  [INFERRED]
  RunAndJump/Nodes/InputController.swift → RunAndJump/Model/AnalogStick.swift
- `GameScene` --calls--> `InvulnerabilityController`  [INFERRED]
  RunAndJump/Scenes/GameScene.swift → RunAndJump/Model/InvulnerabilityController.swift
- `GameScene` --calls--> `JumpController`  [INFERRED]
  RunAndJump/Scenes/GameScene.swift → RunAndJump/Model/JumpController.swift

## Import Cycles
- None detected.

## Communities (25 total, 0 thin omitted)

### Community 0 - "Equatable"
Cohesion: 0.08
Nodes (40): Equatable, Grid, CGPoint, CGSize, LevelBuilder, Int, SKSpriteNode, String (+32 more)

### Community 1 - "CoreGraphics"
Cohesion: 0.06
Nodes (16): CoreGraphics, Foundation, RunAndJump, ObjectSize, CGFloat, WorldMetrics, PhysicsCategory, UInt32 (+8 more)

### Community 2 - "GameScene"
Cohesion: 0.09
Nodes (16): Player, Ladder, CGSize, NSCoder, GameScene, Bool, CGFloat, CGSize (+8 more)

### Community 3 - "OscillatingMotion"
Cohesion: 0.09
Nodes (20): FrameClock, TimeInterval, OscillatingMotion, CGFloat, CGPoint, TimeInterval, PatrollingMovement, CGFloat (+12 more)

### Community 4 - "Player"
Cohesion: 0.07
Nodes (23): PlayerAnimation, PlayerAnimationState, idle, jumping, running, PlayerFacing, left, right (+15 more)

### Community 5 - "PlayerState"
Cohesion: 0.10
Nodes (19): GameEvent, bonusPickup, enemyHit, healthPickup, reachedPortal, GameRules, LevelOutcome, completed (+11 more)

### Community 6 - "LadderController"
Cohesion: 0.19
Nodes (10): LadderAction, climb, idle, releaseLadder, startClimbing, LadderController, Bool, CGFloat (+2 more)

### Community 7 - "GameProgress"
Cohesion: 0.10
Nodes (15): GameProgress, GameProgressRules, Bool, Int, NSCoder, CGSize, Int, NSCoder (+7 more)

### Community 8 - "PlatformRideController"
Cohesion: 0.18
Nodes (12): CGRect, PlatformRideAction, idle, ride, PlatformRideController, Bool, CGFloat, CGPoint (+4 more)

### Community 9 - "InputController"
Cohesion: 0.18
Nodes (14): AnyObject, GameInputDelegate, InputController, Bool, CGFloat, CGPoint, CGSize, NSCoder (+6 more)

### Community 10 - "JumpController"
Cohesion: 0.29
Nodes (5): JumpController, Bool, TimeInterval, JumpControllerLadderTests, JumpControllerTests

### Community 11 - "AnalogStick"
Cohesion: 0.23
Nodes (6): AnalogStick, CGFloat, CGVector, AnalogStickTests, Bool, CGFloat

### Community 12 - "GroundContactTracker"
Cohesion: 0.12
Nodes (9): GroundContactTracker, Bool, Set, RunAndJumpUITests, RunAndJumpUITestsLaunchTests, Bool, Support, XCTest (+1 more)

### Community 13 - "GamepadInput"
Cohesion: 0.19
Nodes (9): GameController, GCController, GCExtendedGamepad, NSObjectProtocol, GamepadInput, Bool, CGFloat, CGVector (+1 more)

### Community 14 - "InvulnerabilityController"
Cohesion: 0.44
Nodes (4): InvulnerabilityController, Bool, TimeInterval, InvulnerabilityControllerTests

### Community 15 - "CLAUDE.md"
Cohesion: 0.20
Nodes (8): Architecture, Build & Test — ALWAYS use XcodeBuildMCP, Conventions & Constraints, Model layer (`RunAndJump/Model/`, `Levels/`) — pure Swift, no SpriteKit, Project, Scene / Node layer (`Scenes/`, `Nodes/`, `Movement/`) — SpriteKit, Testing, Working Style

### Community 16 - "SpriteKit"
Cohesion: 0.20
Nodes (4): StationaryMovement, SKNode, TimeInterval, SpriteKit

### Community 17 - "PickupKind"
Cohesion: 0.24
Nodes (8): Pickup, PickupKind, bonus, health, CGSize, Int, NSCoder, SKColor

### Community 18 - "ContentView.swift"
Cohesion: 0.22
Nodes (7): App, ContentView, SKScene, PlatformerApp, Scene, SwiftUI, View

### Community 19 - "Enemy"
Cohesion: 0.25
Nodes (5): EnemyMovement, Enemy, CGSize, NSCoder, TimeInterval

### Community 20 - "HUDNode"
Cohesion: 0.36
Nodes (5): HUDNode, CGSize, NSCoder, SKLabelNode, SKSpriteNode

### Community 21 - "LevelObject"
Cohesion: 0.25
Nodes (5): LevelObject, CGSize, NSCoder, SKColor, TimeInterval

### Community 22 - "Decoration"
Cohesion: 0.33
Nodes (4): Decoration, CGSize, NSCoder, SKTexture

### Community 23 - "Platform"
Cohesion: 0.40
Nodes (3): Platform, CGSize, NSCoder

### Community 24 - "Portal"
Cohesion: 0.40
Nodes (3): Portal, CGSize, NSCoder

## Knowledge Gaps
- **42 isolated node(s):** `playing`, `died`, `completed`, `enemyHit`, `healthPickup` (+37 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GameScene` connect `GameScene` to `Equatable`, `OscillatingMotion`, `PlayerState`, `LadderController`, `GameProgress`, `PlatformRideController`, `InputController`, `JumpController`, `GamepadInput`, `InvulnerabilityController`, `SpriteKit`, `HUDNode`?**
  _High betweenness centrality (0.423) - this node is a cross-community bridge._
- **Why does `Foundation` connect `CoreGraphics` to `Player`, `PlayerState`, `LadderController`, `GameProgress`, `PlatformRideController`, `GroundContactTracker`?**
  _High betweenness centrality (0.115) - this node is a cross-community bridge._
- **Why does `CoreGraphics` connect `CoreGraphics` to `Equatable`, `Player`, `PlatformRideController`, `AnalogStick`, `GamepadInput`?**
  _High betweenness centrality (0.093) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `GameScene` (e.g. with `InvulnerabilityController` and `JumpController`) actually correct?**
  _`GameScene` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 18 inferred relationships involving `LadderController` (e.g. with `GameScene` and `.climbDownProducesNegativeVelocity()`) actually correct?**
  _`LadderController` has 18 INFERRED edges - model-reasoned connections that need verification._
- **Are the 12 inferred relationships involving `PlayerState` (e.g. with `.levelCompletionCarriesBonusAndAdvances()` and `.subsequentLevelCarriesAccumulatedBonus()`) actually correct?**
  _`PlayerState` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 15 inferred relationships involving `JumpController` (e.g. with `GameScene` and `.bufferedJumpFiresOnLadderRelease()`) actually correct?**
  _`JumpController` has 15 INFERRED edges - model-reasoned connections that need verification._