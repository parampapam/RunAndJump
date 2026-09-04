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

Это же и делает CI (`.github/workflows/tests.yml`) на каждый PR и пуш в `main`.
Гоняются **только** `RunAndJumpTests`: в UI-таргете лежат шаблонные заглушки
Xcode, и `testLaunchPerformance` регулярно падает на сборе метрики запуска —
красный CI, ничего не говорящий о коде. Симулятор выбирается по факту (сначала
`iPhone 17`, иначе любой доступный iPhone): набор симуляторов в образах раннера
меняется, и прибитое имя однажды сломало бы сборку на ровном месте.

## Architecture

The codebase is split into two clearly separated layers. **This separation is load-bearing — never blur it.**

### Model layer (`RunAndJump/Model/`, `Levels/`) — pure Swift, no SpriteKit

All game logic lives here as value types (structs/enums) with pure functions. This is what the unit tests cover.

- **`GameRules`** — static functions that apply events to `PlayerState` and return outcomes. Events: `enemyHit`, `healthPickup`, `bonusPickup(points)`, `reachedPortal`.
- **`HealthConfiguration` / `HealthRules`** — шкала здоровья в очках и все числа её баланса в одном месте: старт (100), потолок (200), урон касания врага (20), вес аптечки (10), пороги цвета шкалы. `GameRules.apply` и `GameProgressRules.initialPlayerState` принимают конфигурацию параметром со значением `.standard`, так что подкрутить сложность = поменять `HealthConfiguration.standard`. `HealthRules` — чистые производные для HUD: `clamp` (0...maximum), `fillFraction` (доля потолка) и `level` (`healthy` / `warning` / `critical`).
- **`GameProgress` / `GameProgressRules`** — всё, что переживает пересоздание `GameScene`: индекс уровня, накопленный бонус, активная точка восстановления (`activeCheckpointIndex`), уже поднятые награды (`collectedPickupIndices`) и засчитанные победы над врагами (`defeatedEnemyIndices`). Три перехода: `checkpointReached` (точка смещается, победы засчитываются окончательно), `playerDied` (очки уходят в перенос за вычетом возвращаемых врагов) и `levelCompleted` (индекс +1, оба списка и точка обнуляются — они у каждого уровня свои). Четвёртый переход — `levelRestarted` («начать уровень заново» из паузы): уровень собирается как при первом входе, а счёт откатывается к `bonusPointsAtLevelStart` — очкам на входе в уровень. Откат обязателен: перезапуск возвращает на уровень все награды, и без него это была бы ферма очков (то же правило, что и у возвращаемых гибелью врагов). Поле необязательное (`Int?`) намеренно — обязательный ключ сделал бы нечитаемыми старые сохранения; `nil` = «не знаем», и откатывать нечего. Ещё `isResumable` отвечает на вопрос запуска «есть ли что продолжать» (сохранение годится и не совпадает с началом игры).
  `GameProgress` — `Codable`, потому что это же значение и сохраняется между запусками. Ещё две чистые функции про сохранение: `snapshot` (подмешивает очки, набранные *прямо сейчас*, — внутри уровня они живут в `PlayerState`, а не в прогрессе) и `resumable` (годится ли прочитанное сохранение для текущего набора уровней; проверяется только индекс уровня — остальные индексы отказоустойчивы сами).
- **`PauseMenu` / `PauseMenuAction`** — содержимое окна паузы: заголовок и три пункта (`resume` / `restartLevel` / `mainMenu`). Последний — **выход**, а не сброс: сохранение он не трогает ни в какую сторону (см. слой хранения), начать партию заново игрок может уже из главного меню. Причина паузы не различается и параметром никуда не ходит: кнопка паузы и сворачивание приложения прерывают живой уровень одинаково, и «продолжить» в обоих случаях значит «вернуться туда же, где стоял». Возвращение в партию после выгрузки приложения окна паузы не касается — его встречает главное меню (`MainMenu`).
- **`MainMenu` / `MainMenuAction` / `MainMenuItem`** — содержимое главного меню: заголовок и четыре пункта сверху вниз — `continueGame`, `newGame`, `settings`, `about`. Порядок постоянный и не зависит ни от сохранения, ни от готовности разделов. Недоступный пункт (`isEnabled == false`) **виден, но не нажимается** — прятать его нельзя, иначе остальные съезжают и кнопка «переезжает» между запусками. Гасятся двое: «продолжить» без сохранения (единственный вопрос, который меню задаёт наружу — параметр `hasSavedGame`) и разделы, экранов которых ещё нет. Главное действие экрана помечает `isPrimary` — узел выделяет его цветом. Оно всегда одно и всегда доступное: акцент идёт за первым доступным пунктом (есть сохранение → «продолжить», нет → «начать заново»), а не приколочен к одному действию, иначе на первом запуске подсвеченной оказалась бы погашенная кнопка.
- **`EnemyRespawnRules`** — сколько очков снять за врагов, возвращаемых на уровень. Отдельно от `GameProgress`, потому что это правило про *врагов*, а не про прогресс: считает по `EnemyKind.defeatPoints`, неизвестные индексы игнорирует.
- **`CheckpointRules`** — точки восстановления (зелёные флаги): где игрок возрождается (`respawnOrigin` — последняя пройденная точка, до первой — `playerStart`), что делать при проходе мимо флага (`activation`) и какой флаг поднят (`state`). Активная точка хранится **индексом** в `LevelConfiguration.checkpoints`: индекс переживает пересоздание сцены, координата всегда достаётся из конфигурации.
- **`BackgroundDescriptor` / `BackgroundLayout`** — фон уровня: сплошная заливка и две горизонтальные полосы поверх неё — нижняя (`HorizonSegment`: холмы, горы, океан) и верхняя (`SkySegment`: облака). Полоса задаётся списком сегментов, и список **зациклен**: уровень перечисляет один период узора, а не мостит всю свою длину. Пустого фона нет — `.fill` / `.clear` просто ничего не рисуют, и на их месте видна заливка. `BackgroundLayout` считает, где лежит полоса при текущей камере: содержимое полосы **короче уровня**, потому что параллакс сжимает её мир — длина = `видимая ширина + f × ход камеры`, а левый край = `край видимой области × (1 − f)`. Поэтому запаса по краям не нужно, полоса доезжает ровно. Скорости (`BackgroundParallax`) — константы, а не поля уровня: иначе одинаковые на вид горы ездили бы на разных уровнях по-разному. По вертикали обе полосы едут **одинаково** (`BackgroundParallax.vertical`) — разные скорости развели бы верх нижней полосы и низ верхней, и при подъёме игрока между ними открылась бы щель.
- **`FrameClock`** — абсолютная метка времени кадра → дельта `dt`, **с потолком** (`defaultMaximumDelta`, 1/30 с). Потолок обязателен: часы кадров идут, пока приложение свёрнуто, и первый кадр после разворачивания дал бы дельту в десятки секунд — враги телепортируются, платформы улетают за свой диапазон. Всё, что ведётся по времени, обязано идти через него, а не вычитать метки вручную.
- **`JumpController`** — manages coyote time (0.1 s after leaving ground) and jump buffering (0.1 s input window before landing). Call `didTouchGround`, `didLeaveGround`, `didPressJump`, then `consumeJumpIfPossible`.
- **`LevelConfiguration`** — declarative struct defining scene size, player start, ground, enemies, pickups, portal positions and the level's **style** (`LevelStyleID`). No SpriteKit types here. **All object positions are in tiles, anchored to the bottom-left corner** (`TileCoordinate`, `TileSize`, `TileRect` — also defined here).
- **`DecorationID` / `LevelStyleID`** — открытые идентификаторы по образцу `Notification.Name`. Правило разделения: если код на этом **ветвится** — закрытый `enum` (`EnemyKind`, `HazardKind`, `PickupKind`, сегменты фона, `DecorationLayer`); если от этого зависит **только картинка** — открытый идентификатор. За `DecorationKind` не стояло ничего, кроме раскладки плиток, и закрытый тип лишь запрещал стилю иметь свой набор украшений. Идентификаторы декораций **локальны стилю**: `"torch"` в подземелье и в замке — разные записи в разных каталогах, ни алиасов, ни глобального реестра.
- **`LevelValidation`** — чистые проверки каталога стиля и уровня против него. Замена компилятору: открытое имя опечатку не ловит. Политика разная по категориям и это решение, а не мелочь: пустая **механическая роль** (плитка платформы) — уровень не собрать; **незнакомая декорация** — в DEBUG `assertionFailure`, в релизе пропуск, терять уровень из-за лишнего цветочка нельзя.
- **`Levels` enum** — hardcodes the three levels as `LevelConfiguration` values, authored on a clean tile grid. Ground is one tile tall, so its top is at `y: 1` — objects "on the ground" use `y: 1`.
- **`PhysicsCategory`** — bitmask constants for SpriteKit physics contacts.
- **`WorldMetrics`** — world scale constants: `tileSize` (60 pts/tile) and `visibleTilesTall` (camera zoom — how many tiles tall the scene shows).
- **`Grid`** — pure tile↔point conversion (`point`, `size`, `center(of:)`). Converts the bottom-left tile origin used by descriptors into the centred point position SpriteKit nodes expect. The conversion lives here (tested), nodes stay centred so physics bodies are unaffected.
- **`ObjectSize`** — canonical tile sizes (in tiles) for objects whose dimensions are always the same (`player`, `enemy`, `pickup`, `portal`). Single source of truth: both the node and `Grid.center` placement read from it.
- **`PlayerAnimation` / `PlayerAnimationState`** — pure selection of animation state (idle / running / jumping) and facing (left/right) from `isOnGround` and horizontal input. Relies on `isOnGround` being stable (supports rest with `restitution = 0`).

### Resources layer (`Resources/`) — стиль как данные

Оформление уровня описывается данными, а не зашито в узлы. Слой делится надвое: каталог — чистые данные (тестируется без SpriteKit), тема — SpriteKit, но не узел.

- **`StyleCatalog` / `TerrainNames` / `BackgroundNames` / `DecorationEntry`** — чем нарисован стиль. Каталог разделён надвое намеренно: `terrain` — **механические роли** (без плитки платформы играть нельзя), поэтому они поля и забыть их не даст компилятор; `decorations` — **украшения**, поэтому словарь по открытому `DecorationID`: набор у каждого стиля свой. Кадр плитки — **всегда список**, статичная декорация это список из одного элемента; отдельной формы записи для статики нет. `frameDuration` — **на запись, а не на плитку**: многоплиточная анимация (костёр 1×2, водопад) обязана идти в такт, и общая длительность — единственный способ это гарантировать (то же правило у озёр). `randomizePhase` сдвигает **начало** цикла, а не темп: два факела рядом не мигают в унисон. `skyColor` **обязан** совпадать с цветом заливки фона — этим цветом залиты края фоновых картинок, иначе станет виден их прямоугольник.
- **`Resources/Styles/`** — сами каталоги (`GrasslandCatalog`) и реестр `StyleCatalogs`: единственное место, где `LevelStyleID` превращается в каталог.
- **`LevelTextures`** — тема уровня: каталог плюс его атласы и разрешение имени в `SKTexture`. Ради неё всё и затевалось: раньше атласы лежали в `static let` прямо в узлах, и подменить их снаружи было нельзя — скрытое глобальное состояние, из-за которого второй стиль был невозможен в принципе. Теперь тему создаёт `GameScene` по `configuration.style` и раздаёт вниз.
- **Стиля не имеют игрок, враги, награды, снаряды и HUD.** Их атласы общие на всю игру, имена лежат в `TextureName`. Это **осознанная граница**, а не недоделка: иначе к третьему стилю пришлось бы рисовать своего игрока каждому.

### Persistence layer (`Persistence/`) — ввод-вывод на краю

- **`GameProgressStore`** — протокол «сохранить / загрузить / забыть» `GameProgress`. Реализации: `UserDefaultsProgressStore` (один JSON под ключом `game.progress.v1`) и `NullProgressStore` (пустышка для превью и тестов). Хранилище инжектируется в `GameScene` и передаётся дальше при каждом её пересоздании; ни сцена, ни модель не знают, что под ним.
- **Когда сохраняем**: подъём флага, гибель, конец уровня — то есть в моменты игровых событий, а **не** по сигналам жизненного цикла. Свёрнутое приложение iOS выгружает без предупреждения, и надёжного «сохранись перед смертью» не существует. Сохраняется и перезапуск уровня из паузы. Стирают сохранение два случая: прохождение всей игры и «начать новую игру» в главном меню — иначе следующий запуск предложил бы продолжить брошенную партию.
- **Выход в главное меню сохранение не пишет и не стирает.** Не стирает, потому что это навигация, а не сброс: уничтожать партию за то, что игрок открыл меню, нельзя. Не пишет, потому что снимок посреди уровня несогласован — награды уже отмечены в `progress`, а побеждённые с последнего флага враги ещё нет, и после «продолжить» они вернутся на уровень живыми, тогда как очки за них останутся (то же, от чего защищает `EnemyRespawnRules` при гибели). Поэтому выход в меню равен выгрузке приложения: продолжение начнётся с последнего флага, всё после него потеряется.
- **Что не сохраняется**: положение игрока внутри уровня, здоровье, живые враги. Продолжение = возрождение на последнем флаге с полным здоровьем, ровно как после гибели. Сериализовать состояние сцены дорого и хрупко, а для платформера такая семантика ожидаема.

### Scene / Node layer (`Scenes/`, `Nodes/`, `Movement/`) — SpriteKit

- **`GameHost` + `ContentView`** — шов SwiftUI↔SpriteKit. Сцена лежит в `@StateObject`, поэтому создаётся **один раз** за жизнь экрана: собранная в `body`, она стиралась бы при любом пересчёте `body` и игра молча возвращалась бы в меню. Первую сцену — всегда `MainMenuScene` — собирает `GameHost`, дальше сцены сменяют друг друга сами через `presentScene`, минуя SwiftUI. Тип свойства — `SKScene`, а не `GameScene`: какой экран открыт сейчас, SwiftUI не касается.
- **`MainMenuScene`** — главное меню, первое, что видит игрок. Отдельная **сцена**, а не окно поверх игры: пока меню открыто, уровня не существует вовсе, поэтому и просвечивать сквозь него нечему (окно паузы устроено иначе именно потому, что за ним обязан быть виден живой уровень). Рисует то, что описано в `MainMenu`, спрашивает у `GameProgressStore`, есть ли что продолжать (`GameProgressRules.isResumable`), и собирает `GameScene` по выбору игрока. «Начать заново» стирает сохранение — это единственное место в игре, где оно стирается по воле игрока. Раскладка центрирована через `anchorPoint` в середине сцены, поэтому переживает любой размер экрана без пересборки.
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
- **`Background`** — фон уровня: заливка на весь уровень плюс две полосы, которые сцена двигает за камерой (`updateBackground` **после** `updateCamera`, иначе полосы отстают на кадр). Узел ничего не решает: раскладку даёт `BackgroundLayout`, текстуры — тема уровня (`LevelTextures`), у каждого стиля свои холмы и облака. Спрайты собираются один раз и потом только смещаются целиком — пересборка нужна лишь при смене размера видимой области (поворот экрана), от которой зависит число сегментов. `Grid` живёт и здесь, а не только в `LevelBuilder`: полосы едут каждый кадр, а не встают один раз при сборке уровня.
- **`Portal`** — level exit (purple).
- **Пауза** — кнопка паузы в HUD (`PauseButton`, справа сверху) открывает `PauseMenuNode`: затемнение на весь экран, заголовок и три кнопки. Узел ничего не решает — тексты и пункты берёт из `PauseMenu`, а выбор отдаёт сцене. Останавливает игру сцена: `isPaused` (действия и физика) + ранний выход из `update()`. Дублирование намеренное и **самовосстанавливающееся**: `isPaused` сбрасывает сам SKView, когда приложение возвращается в активное состояние, поэтому попадание в `update()` на паузе трактуется как «паузу сняли снаружи» и ставит её обратно.
- **Сворачивание приложения ставит паузу само** — `GameScene` подписана на `UIApplication.willResignActive` (не на `didEnterBackground`: шторка уведомлений и переключатель приложений оставляют игру живой, хотя управлять ею уже нельзя). Подписка живёт в сцене, а не в SwiftUI, потому что `GameHost` держит только первую сцену — дальше `GameScene` пересоздаёт себя сама, и ссылка снаружи указывала бы на выброшенную сцену. Сворачивание — это **только** пауза: сохранение по-прежнему случается в моменты игровых событий (см. слой хранения), полагаться на сигналы жизненного цикла нельзя. Открытое окно — оно же признак паузы (`pauseMenu != nil`), отдельного флага нет. Ввод на паузе игнорируется (геймпад продолжает слать события), а экранное управление скрыто; видимость кнопок считает **одна** функция `updateControlsVisibility` («игра идёт и нет геймпада»): подключение геймпада приходит уведомлением в произвольный момент и раздельными вызовами затирало бы паузу.
- **`HUDNode`** — прогресс-бар здоровья с подписью «очки/потолок» и счётчик бонусов. Заполненность и цвет заливки считает модель (`HealthRules`), узел только рисует: раскладка и цвета — в приватных `Layout` / `HUDPalette` в том же файле.
- **`InputController`** — on-screen draggable analog joystick (left) + jump button (right); analog deflection math lives in the pure `AnalogStick`. `GamepadInput` mirrors the same commands from a physical controller and hides the on-screen controls while connected.
- **`LevelBuilder`** — factory that creates SpriteKit nodes from descriptor structs in `LevelConfiguration`. **The single place tile coordinates are converted to points** (via `Grid`): descriptors are authored in tiles / bottom-left, nodes get a centred point position here. Структура с темой (`LevelTextures`), а не `enum` со статическими атласами: два уровня в разных стилях собираются одним и тем же кодом. Узлы ландшафта (`PlatformSkin`, `Ladder`, `Background`) получают текстуры параметром и про стиль не знают.
- **`Decoration`** — декорация из плиток; `DecorationLayer` выбирает слой: `back` (за игроком, `ZPosition.decorationBack`) или `front` (перед ним, `decorationFront = 3` — выше игрока, но ниже жидкости, чтобы факел не всплывал поверх лавы). Узел ничего не решает: спрайты приходят собранными и, если надо, уже анимированными — это делает `LevelBuilder` по каталогу.

## Testing

Uses **Swift Testing** (`@Test` macros, `#expect`, `#require` — not XCTest). Tests are in `RunAndJumpTests/` and cover **only the model layer**:

- `GameRulesTests` — state transitions and outcomes
- `JumpControllerTests` — coyote time, jump buffering, double-jump prevention
- `GameProgressTests` — level advancement and bonus carryover

When adding new game logic, the test for it goes in the model layer too. If something feels untestable, it probably has a SpriteKit dependency that needs to be extracted into a pure type first.

**Одно исключение из правила «только модель»: `StyleAssetsTests`** — он импортирует SpriteKit намеренно. Каталог стиля называет текстуры строками, компилятор их не проверяет, а опечатка даёт не ошибку сборки, а розовый квадрат в игре; сверить имя с настоящим атласом можно только спросив сам атлас. Исключение записано здесь, чтобы следующая уборка не удалила файл как не соответствующий конвенции. Расширять его нельзя: всё, что можно проверить без SpriteKit, проверяет `LevelValidationTests`.

## Working Style

- Proactively suggest architecture improvements: point out when code could be more testable, when responsibilities are mixed, when a value type would fit better than a class, when a dependency should be injected.
- Prefer clarity over cleverness. Explain *why* a design choice helps, not just *what* to change.
- When reviewing code, flag tight coupling, hidden state, and untestable side effects even if I didn't ask.
- When writing new code, default to pure functions and value types where the language allows; isolate I/O and framework dependencies at the edges.

## Conventions & Constraints

**Layer hygiene**
- Never add `import SpriteKit` (or any SK type) to files under `Model/` or `Levels/`. If you need a position, use `CGPoint` from CoreGraphics, not an `SKNode`.
- New gameplay logic → pure functions / value types in `Model/`, covered by a Swift Testing test.
- Каталог стиля (`Resources/StyleCatalog.swift`, `Resources/Styles/`) — тоже без SpriteKit: он оперирует **именами** текстур, а не текстурами. `SKTexture` появляется только в `LevelTextures`. Не заводите в каталоге `SKColor`, `SKTexture` или `zPosition` числом — для цвета есть `RGBColor`, для слоя `DecorationLayer`.
- Данные выбирают из того, что умеет код, и никогда не описывают поведение сами. Как только каталог начнёт описывать поведение, он превратится в скриптовый движок.

**Extension points**
- New enemy behaviour → implement `EnemyMovement`, don't subclass `Enemy`.
- New enemy variant (same two movement types) → add a case to `EnemyKind` plus its frames in `AnimationFrames.Enemy` / `AnimationDuration.Enemy`; nothing in the node or the builder needs to change.
- New shooting enemy → return an `EnemyWeapon` from `EnemyKind.weapon`; `Enemy`, `LevelBuilder` and `GameScene` already handle any armed kind. Tuning an existing shooter = changing the numbers in that one `EnemyWeapon`.
- Place enemies with `EnemyDescriptor.stationary(_:at:)` / `.patrolling(_:at:leftX:rightX:speed:)` — the patrol range only exists for kinds that walk.
- New level → add a `LevelConfiguration` to the `Levels` enum, don't create a new SKScene subclass. У уровня обязателен `style`.
- Новая декорация → добавить запись в `decorations` каталога стиля (и, для удобства кода, имя в расширении `DecorationID` рядом с этим каталогом). Ни узел, ни билдер, ни сцена не меняются. Анимация не требует нового вида записи: плитка с одним кадром статична, с несколькими — крутится, длительность кадра одна на запись.
- **Новый стиль** → положить его атласы в `Assets.xcassets`, написать каталог в `Resources/Styles/`, добавить его в `StyleCatalogs.all` и завести `LevelStyleID`. В коде для этого не меняется **ничего**; перевести уровень на новый стиль = поправить одно поле. Ловушка ассетов: папки в `.xcassets` — **не** пространства имён, если не включено «Provides Namespace», а фон читается по имени картинки, поэтому `bg_hills` в двух стилях столкнутся — префиксуйте имена слоёв фона (`dungeon_bg_hills`). У плиточных атласов такой проблемы нет: атлас сам себе пространство имён.
- Опечатка в открытом идентификаторе ловится не компилятором, а тестами: `LevelValidationTests` (чистые проверки) и `StyleAssetsTests` (имена против настоящих атласов). Оба проходят по **всем** каталогам и **всем** уровням, так что новый стиль подключается к ним сам.
- Паузы подвижной платформы → список `MotionStop` в её `MovingPlatformDescriptor.stops`. Остановка — это «где» (доля пути: 0 = `start`, 1 = `end`) и «сколько» (секунды), поэтому пауз может быть сколько угодно и в любой точке маршрута: `[.start(0.5), .at(0.5, 1.0)]` — полсекунды в начале, секунда в середине, в конце без паузы. Место задаётся долей, а не тайлами, потому что доля переживает сдвиг концов платформы. Концы — **не особый случай**: это остановки с прогрессом 0 и 1, а разворот на них происходит и без остановки. «Паузы нет» = остановки нет в списке (`stops: []` — ход без пауз, `MotionStop.atEnds(_:)` — одинаковая пауза в обоих концах); нулевую длительность писать бессмысленно — она отбрасывается. Кадр тратится целиком: доезд, пауза и разъезд укладываются в один `advance`, поэтому расписание не плывёт от числа остановок, а пауза короче кадра отрабатывает честно.
- Новый вид фона → добавить случай в `HorizonSegment` / `SkySegment` и поле под него в `BackgroundNames` (слой ресурсов знает, чем сегмент нарисован, модель — только какой он). Поля, а не словарь по сегментам: новый сегмент **обязан** сломать сборку каждого каталога, а не тихо остаться ненарисованным. Узор фона уровня правится в его `BackgroundDescriptor`: чередование сегментов, ширина сегмента и высота линии горизонта. Ширина сегмента не обязана совпадать с пропорцией картинки — у изображений фона левый и правый край однотонные, растягивается только заливка. **Узор держат коротким** (порядка четырёх сегментов): список длиннее полосы показывает только начало, а хвост не увидят никогда, и сколько влезет — зависит от размера экрана. Каждый слой фона — отдельный **Image Set**, а не кадр в атласе: слои рисуются по одному, каждый со своим `zPosition`, и паковать их вместе незачем. Новая картинка должна иметь тот же цвет неба, что и заливка (`bg_fill_day`, `#B7CAF4`), иначе её прямоугольник станет виден.
- Новая точка восстановления → добавить `CheckpointDescriptor` в `LevelConfiguration.checkpoints`; узел, подъём флага и возрождение уже общие. Координата флага — это и место появления игрока, поэтому ставить только туда, где он может стоять (земля `y: 1` или платформа). Порядок в массиве — идентификатор точки, так что вставка флага в середину списка на уже начатом уровне сместила бы активную точку.
- New hazard type (кислота, шипы) → add a case to `HazardKind` with its damage / interval, its frames in `AnimationFrames.Hazard` / `AnimationDuration.Hazard`, и непрозрачность в приватном расширении в `Hazard.swift`; the scene and the builder already handle any kind. Place hazards with `HazardDescriptor(kind:rect:)` — прямоугольник задаёт сразу вид, зону урона и проём в земле, поэтому только целые тайлы по сетке: обычное озеро — это ряд земли целиком (`y: 0`, высота 1).
- New pickup type → extend the existing `Pickup` mechanism rather than introducing a parallel node. Новый вид обязан ответить в `PickupKind`, что он даёт (`event`) и возвращается ли после гибели (`staysCollectedAfterDeath`) — сцена эти вопросы не решает.
- Баланс здоровья (старт, потолок, урон врага, вес аптечки, пороги цвета шкалы) → правится только в `HealthConfiguration.standard`; урон озёр живёт в `HazardKind.damage` и задаётся в тех же очках. Ни узлы, ни сцена числа здоровья не знают.
- Новый пункт окна паузы → добавить случай в `PauseMenuAction` и пункт в `PauseMenu.items`; `PauseMenuNode` нарисует его сам, останется описать последствие в `GameScene.handle(pauseAction:)`. Тексты кнопок живут только в `PauseMenu` — узел их не выдумывает.
- Новый пункт главного меню → добавить случай в `MainMenuAction` и пункт в `MainMenu.items(hasSavedGame:)`; `MainMenuScene` нарисует его сам, останется описать последствие в её `handle(_:)`. Готовый раздел = `isEnabled: true` плюс его случай в `switch` (случаи там перечислены явно, чтобы новый пункт ломал сборку, а не тихо проваливался в `default`).
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
