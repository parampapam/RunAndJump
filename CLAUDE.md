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
- **`HealthConfiguration` / `HealthRules`** — шкала здоровья в очках и все числа её баланса в одном месте: старт (100), потолок (200), урон касания врага (20), вес аптечки (10), пороги цвета шкалы. `GameRules.apply` и `GameProgressRules.initialPlayerState` принимают конфигурацию параметром со значением `.standard`, так что подкрутить сложность = поменять `HealthConfiguration.standard`. `HealthRules` — чистые производные для HUD: `clamp` (0...maximum), `fillFraction` (доля потолка) и `level` (`healthy` / `warning` / `critical`).
- **`GameProgress` / `GameProgressRules`** — всё, что переживает пересоздание `GameScene`: индекс уровня, накопленный бонус, активная точка восстановления (`activeCheckpointIndex`), уже поднятые награды (`collectedPickupIndices`) и засчитанные победы над врагами (`defeatedEnemyIndices`). Три перехода: `checkpointReached` (точка смещается, победы засчитываются окончательно), `playerDied` (очки уходят в перенос за вычетом возвращаемых врагов) и `levelCompleted` (индекс +1, оба списка и точка обнуляются — они у каждого уровня свои). Четвёртый переход — `levelRestarted` («начать уровень заново» из паузы): уровень собирается как при первом входе, а счёт откатывается к `bonusPointsAtLevelStart` — очкам на входе в уровень. Откат обязателен: перезапуск возвращает на уровень все награды, и без него это была бы ферма очков (то же правило, что и у возвращаемых гибелью врагов). Поле необязательное (`Int?`) намеренно — обязательный ключ сделал бы нечитаемыми старые сохранения; `nil` = «не знаем», и откатывать нечего. Ещё `isResumable` отвечает на вопрос запуска «есть ли что продолжать» (сохранение годится и не совпадает с началом игры).
  `GameProgress` — `Codable`, потому что это же значение и сохраняется между запусками. Ещё две чистые функции про сохранение: `snapshot` (подмешивает очки, набранные *прямо сейчас*, — внутри уровня они живут в `PlayerState`, а не в прогрессе) и `resumable` (годится ли прочитанное сохранение для текущего набора уровней; проверяется только индекс уровня — остальные индексы отказоустойчивы сами).
- **`PauseMenu` / `PauseReason` / `PauseMenuAction`** — содержимое окна паузы: заголовок, пояснение и три пункта (`resume` / `restartLevel` / `restartGame`). Причин две, и различаются они только словами: обычная пауза (`playerRequested`) и партия, открытая заново после выгрузки приложения (`resumedSession`) — там «продолжить» значит «возродиться на последнем флаге», и это сказано игроку прямым текстом.
- **`EnemyRespawnRules`** — сколько очков снять за врагов, возвращаемых на уровень. Отдельно от `GameProgress`, потому что это правило про *врагов*, а не про прогресс: считает по `EnemyKind.defeatPoints`, неизвестные индексы игнорирует.
- **`CheckpointRules`** — точки восстановления (зелёные флаги): где игрок возрождается (`respawnOrigin` — последняя пройденная точка, до первой — `playerStart`), что делать при проходе мимо флага (`activation`) и какой флаг поднят (`state`). Активная точка хранится **индексом** в `LevelConfiguration.checkpoints`: индекс переживает пересоздание сцены, координата всегда достаётся из конфигурации.
- **`FrameClock`** — абсолютная метка времени кадра → дельта `dt`, **с потолком** (`defaultMaximumDelta`, 1/30 с). Потолок обязателен: часы кадров идут, пока приложение свёрнуто, и первый кадр после разворачивания дал бы дельту в десятки секунд — враги телепортируются, платформы улетают за свой диапазон. Всё, что ведётся по времени, обязано идти через него, а не вычитать метки вручную.
- **`JumpController`** — manages coyote time (0.1 s after leaving ground) and jump buffering (0.1 s input window before landing). Call `didTouchGround`, `didLeaveGround`, `didPressJump`, then `consumeJumpIfPossible`.
- **`LevelConfiguration`** — declarative struct defining scene size, player start, ground, enemies, pickups, and portal positions for a level. No SpriteKit types here. **All object positions are in tiles, anchored to the bottom-left corner** (`TileCoordinate`, `TileSize`, `TileRect` — also defined here).
- **`Levels` enum** — hardcodes the three levels as `LevelConfiguration` values, authored on a clean tile grid. Ground is one tile tall, so its top is at `y: 1` — objects "on the ground" use `y: 1`.
- **`PhysicsCategory`** — bitmask constants for SpriteKit physics contacts.
- **`WorldMetrics`** — world scale constants: `tileSize` (60 pts/tile) and `visibleTilesTall` (camera zoom — how many tiles tall the scene shows).
- **`Grid`** — pure tile↔point conversion (`point`, `size`, `center(of:)`). Converts the bottom-left tile origin used by descriptors into the centred point position SpriteKit nodes expect. The conversion lives here (tested), nodes stay centred so physics bodies are unaffected.
- **`ObjectSize`** — canonical tile sizes (in tiles) for objects whose dimensions are always the same (`player`, `enemy`, `pickup`, `portal`). Single source of truth: both the node and `Grid.center` placement read from it.
- **`PlayerAnimation` / `PlayerAnimationState`** — pure selection of animation state (idle / running / jumping) and facing (left/right) from `isOnGround` and horizontal input. Relies on `isOnGround` being stable (supports rest with `restitution = 0`).

### Persistence layer (`Persistence/`) — ввод-вывод на краю

- **`GameProgressStore`** — протокол «сохранить / загрузить / забыть» `GameProgress`. Реализации: `UserDefaultsProgressStore` (один JSON под ключом `game.progress.v1`) и `NullProgressStore` (пустышка для превью и тестов). Хранилище инжектируется в `GameScene` и передаётся дальше при каждом её пересоздании; ни сцена, ни модель не знают, что под ним.
- **Когда сохраняем**: подъём флага, гибель, конец уровня — то есть в моменты игровых событий, а **не** по сигналам жизненного цикла. Свёрнутое приложение iOS выгружает без предупреждения, и надёжного «сохранись перед смертью» не существует. Сохраняется и перезапуск уровня из паузы. Стирают сохранение два случая: прохождение всей игры и «начать игру сначала» — иначе следующий запуск предложил бы продолжить брошенную партию.
- **Что не сохраняется**: положение игрока внутри уровня, здоровье, живые враги. Продолжение = возрождение на последнем флаге с полным здоровьем, ровно как после гибели. Сериализовать состояние сцены дорого и хрупко, а для платформера такая семантика ожидаема.

### Scene / Node layer (`Scenes/`, `Nodes/`, `Movement/`) — SpriteKit

- **`GameHost` + `ContentView`** — шов SwiftUI↔SpriteKit. Сцена лежит в `@StateObject`, поэтому создаётся **один раз** за жизнь экрана: собранная в `body`, она стиралась бы при любом пересчёте `body` и игра молча начиналась бы заново. Первую сцену собирает `GameHost` (из сохранения, если оно годится), дальше сцены пересоздаёт сама `GameScene` через `presentScene`, минуя SwiftUI. Он же решает, открыть ли первую сцену сразу на паузе: продолженная партия (`GameProgressRules.isResumable`) показывает окно паузы, новая игра начинается сразу.
- **Прыжок сверху убивает врага**: `EnemyContactRules` (модель) решает по геометрии контакта, что это — `stomp` или `damage`; сцена вызывает `Enemy.defeat()` (кадр поражения → исчезновение), `Player.bounceOffEnemy()` и применяет `EnemyKind.defeatEvent` — очки за врага (`defeatPoints`) идут в общий бонус. Физическое тело врага снимается отложенно, через `SKAction`, — менять физику внутри `didBegin` нельзя.
- **Победа над врагом засчитывается флагом, а не сразу**: сцена копит побеждённых в `defeatedSinceCheckpoint` (живёт в сцене и умирает вместе с ней). Подъём флага переносит их в `progress.defeatedEnemyIndices` — эти враги на уровень больше не вернутся. Гибель раньше флага возвращает их и снимает очки за них (`EnemyRespawnRules.refund`), иначе смерть была бы способом набивать очки на одном враге. Правило обратное наградам и осознанно: награда — достижение, её отнимать нельзя; враг — препятствие, и переигрываемый участок должен остаться той же сложности.
- **Стрельба врагов**: оружие — свойство вида (`EnemyKind.weapon: EnemyWeapon?`, есть только у снайпера). `ShootingRules` решает, видит ли стрелок цель (впереди по взгляду, в пределах `sightRange` по X и `verticalTolerance` по Y), `ShootingController` держит тайминги (прицеливание `aimDelay` → выстрел → `cooldown`; потеря цели сбрасывает отсчёт), `ProjectileRules` считает точку вылета, скорость и время жизни. Всё это чистая модель; `Enemy.updateShooting(at:targetPosition:)` только подставляет геометрию узла и возвращает `ProjectileSpawn`, а узел `Projectile` создаёт сцена (`GameScene.updateShooters`), потому что иерархией владеет она. Попадание по игроку — обычный `.enemyHit` с окном неуязвимости; снаряд гаснет и от игрока, и от земли/платформы/стены, и по исчерпании дальности.
- **Озёра воды и лавы**: `HazardKind` (модель) знает урон и паузу между ударами, `Hazard` (узел) — только выкладывает озеро плитками жидкости из атласа `Hazards` (два кадра, все плитки анимируются в такт) и несёт тело-триггер. Озеро лежит в **проёме земли**: земля собирается не сплошной полосой, а кусками между озёрами (чистый `GroundLayout` → `LevelBuilder.makeGround` + травяное покрытие по куску), а на дне ямы лежит отдельная опора — ниже поверхности на `HazardKind.depthInTiles` (`makeHazardFloor`). Поэтому игрок **физически** проваливается в озеро по пояс и выбирается оттуда прыжком, никаких смещений спрайта. Плитки жидкости полупрозрачные и рисуются **поверх** него (`ZPosition.hazard`): видно и утонувшую половину, и небо за ней — грунта под жидкостью нет. У тела `collisionBitMask = none`: сквозь озеро проходят. Сцена держит список зон, в которых игрок сейчас находится (`didBegin`/`didEnd`), и каждый кадр зовёт общий `applyDamage(_:recovery:)` — тот же путь, что для врагов и снарядов, только окно неуязвимости берётся из вида зоны. Поэтому стоящего в лаве жжёт чаще, чем в воде, и оба урона не складываются с ударом врага.
- **`GameScene`** — main SKScene. Initialises from `LevelConfiguration` via `LevelBuilder`, runs the game loop in `update()`, handles `SKPhysicsContactDelegate`, and drives state transitions (playing → died → restart or completed → next level via `GameProgress`).
- **`VictoryScene`** — shown after all levels complete; displays total bonus.
- **`Player`** — one tile in size (`WorldMetrics.tileSize`, 60×60); moves at 250 pts/s horizontally; jump impulse 150 (≈2.3 tiles high). Renders the `Player` sprite atlas, picking frames via `PlayerAnimation` and mirroring by `xScale` for facing. Reads commands from `InputController` / `GamepadInput`.
- **`Enemy`** / `LevelObject` — SpriteKit node with an injected `EnemyMovement` strategy (`StationaryMovement`, `PatrollingMovement`). Carries an `EnemyKind` (crab / imp / sniper — patrolling; plant / wasp — stationary): the kind picks the frames from the `Enemies` atlas via `AnimationFrames.Enemy` and decides the movement style, so a level can't make a plant patrol. Facing comes from the per-frame position delta (`EnemyAnimation.facing`) and mirrors by `xScale`. Enemies and pickups are non-dynamic; their positions are updated manually each frame.
- **`Pickup`** — green = health, yellow = bonus points. Несёт свой индекс в `LevelConfiguration.pickups`: при подборе сцена помечает им награду в `progress.collectedPickupIndices`, если та не возвращается после гибели. Что возвращается, решает модель — `PickupKind.staysCollectedAfterDeath`: монеты нет (очки за них сохранены), аптечки да (здоровье при возрождении сбрасывается до стартового).
- **`Checkpoint`** — флаг точки восстановления: узел-триггер (сквозь него проходят), который только рисует состояние из `CheckpointRules` и подскакивает при подъёме. Решение принимает сцена: проход мимо флага поднимает его, опускает остальные и записывает индекс в `progress`. Рисуется позади игрока (`ZPosition.checkpoint`), потому что игрок появляется ровно на флаге.
- **`Portal`** — level exit (purple).
- **Пауза** — кнопка паузы в HUD (`PauseButton`, справа сверху) открывает `PauseMenuNode`: затемнение на весь экран, заголовок и три кнопки. Узел ничего не решает — тексты и пункты берёт из `PauseMenu`, а выбор отдаёт сцене. Останавливает игру сцена: `isPaused` (действия и физика) + ранний выход из `update()` — дублирование намеренное, `isPaused` сбрасывает сам SKView при возвращении приложения в активное состояние. Открытое окно — оно же признак паузы (`pauseMenu != nil`), отдельного флага нет. Ввод на паузе игнорируется (геймпад продолжает слать события), а экранное управление скрыто; видимость кнопок считает **одна** функция `updateControlsVisibility` («игра идёт и нет геймпада»): подключение геймпада приходит уведомлением в произвольный момент и раздельными вызовами затирало бы паузу.
- **`HUDNode`** — прогресс-бар здоровья с подписью «очки/потолок» и счётчик бонусов. Заполненность и цвет заливки считает модель (`HealthRules`), узел только рисует: раскладка и цвета — в приватных `Layout` / `HUDPalette` в том же файле.
- **`InputController`** — on-screen draggable analog joystick (left) + jump button (right); analog deflection math lives in the pure `AnalogStick`. `GamepadInput` mirrors the same commands from a physical controller and hides the on-screen controls while connected.
- **`LevelBuilder`** — factory that creates SpriteKit nodes from descriptor structs in `LevelConfiguration`. **The single place tile coordinates are converted to points** (via `Grid`): descriptors are authored in tiles / bottom-left, nodes get a centred point position here.

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
- New enemy variant (same two movement types) → add a case to `EnemyKind` plus its frames in `AnimationFrames.Enemy` / `AnimationDuration.Enemy`; nothing in the node or the builder needs to change.
- New shooting enemy → return an `EnemyWeapon` from `EnemyKind.weapon`; `Enemy`, `LevelBuilder` and `GameScene` already handle any armed kind. Tuning an existing shooter = changing the numbers in that one `EnemyWeapon`.
- Place enemies with `EnemyDescriptor.stationary(_:at:)` / `.patrolling(_:at:leftX:rightX:speed:)` — the patrol range only exists for kinds that walk.
- New level → add a `LevelConfiguration` to the `Levels` enum, don't create a new SKScene subclass.
- Новая точка восстановления → добавить `CheckpointDescriptor` в `LevelConfiguration.checkpoints`; узел, подъём флага и возрождение уже общие. Координата флага — это и место появления игрока, поэтому ставить только туда, где он может стоять (земля `y: 1` или платформа). Порядок в массиве — идентификатор точки, так что вставка флага в середину списка на уже начатом уровне сместила бы активную точку.
- New hazard type (кислота, шипы) → add a case to `HazardKind` with its damage / interval, its frames in `AnimationFrames.Hazard` / `AnimationDuration.Hazard`, и непрозрачность в приватном расширении в `Hazard.swift`; the scene and the builder already handle any kind. Place hazards with `HazardDescriptor(kind:rect:)` — прямоугольник задаёт сразу вид, зону урона и проём в земле, поэтому только целые тайлы по сетке: обычное озеро — это ряд земли целиком (`y: 0`, высота 1).
- New pickup type → extend the existing `Pickup` mechanism rather than introducing a parallel node. Новый вид обязан ответить в `PickupKind`, что он даёт (`event`) и возвращается ли после гибели (`staysCollectedAfterDeath`) — сцена эти вопросы не решает.
- Баланс здоровья (старт, потолок, урон врага, вес аптечки, пороги цвета шкалы) → правится только в `HealthConfiguration.standard`; урон озёр живёт в `HazardKind.damage` и задаётся в тех же очках. Ни узлы, ни сцена числа здоровья не знают.
- Новый пункт окна паузы → добавить случай в `PauseMenuAction` и пункт в `PauseMenu.items`; `PauseMenuNode` нарисует его сам, останется описать последствие в `GameScene.handle(pauseAction:)`. Тексты кнопок живут только в `PauseMenu` — узел их не выдумывает.
- Новое место хранения прогресса (файл, iCloud) → реализовать `GameProgressStore`; `GameScene` знает только протокол. **Новое поле в `GameProgress`** автоматически попадает в сохранение, но ломает чтение старых: синтезированный `Codable` требует ключ и **не** подставляет значение по умолчанию (необязательное поле — исключение, отсутствие читается как `nil`). Сломанное чтение не роняет игру — нечитаемое трактуется как «сохранения нет», — но прогресс игроков теряется; если это неприемлемо, нужна миграция.

**Level authoring (tiles)**
- Author positions in **tiles, anchored to the bottom-left corner** — `TileCoordinate` for point objects (player/enemy/pickup/portal), `TileRect` (origin + size) for sized ones (platforms/ladders/moving platforms). Fractional tiles are allowed for off-grid offsets.
- Ground top is `y: 1` (ground is one tile tall); put on-ground objects at `y: 1`.
- A fixed-size object's dimensions come from `ObjectSize` — don't hardcode point sizes in the node. Tile→point conversion happens only in `LevelBuilder` via `Grid`; never set a node's point position from a descriptor directly.
- `speed` (patrol / moving platform) stays in **points/s**, not tiles/s.

**Project file**
- Do not edit `.pbxproj` by hand. Never patch the project file to register files.
- This project uses **file-system-synchronized groups** (`PBXFileSystemSynchronizedRootGroup`, `objectVersion = 77`, Xcode 16+): the `RunAndJump`, `RunAndJumpTests`, and `RunAndJumpUITests` folders auto-include whatever `.swift` files live in them. So creating a new file in those folders is fine — it joins the target with no `.pbxproj` change. Just match the existing folder layout (`Model/`, `Levels/`, `Nodes/`, …).
- The exception: if a non-synchronized (classic) group is ever added, files in it must be registered in `.pbxproj` — that needs Xcode, so stop and tell me instead.

**Style**
- Swift Testing for all new tests (`@Test`, `#expect`), never XCTest.
- Value types (struct/enum) by default in the model layer; classes only where SpriteKit requires reference semantics.
- Keep the game loop in `update()` ordered: input → player movement → enemy movement → contact resolution → HUD.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
