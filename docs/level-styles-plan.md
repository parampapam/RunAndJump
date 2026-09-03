# Стили уровней

План перевода оформления уровня в данные: открытый каталог декораций вместо
закрытого `enum`, тема вместо статических атласов, валидация вместо
компилятора — и только потом уровни из JSON.

Ветка: `claude/level-style-system-0b69e2`. Шагов — 6. Первый видимый на экране
результат — на шаге 5.

## Что решено до начала

Четыре ответа, на которых стоит весь план. Каждый из них что-то *убирает* из
объёма — их стоит держать в голове при любом соблазне «сделать пообщее».

- **Переносимость уровня между стилями не нужна.** Идентификаторы декораций
  локальны стилю: `"torch"` в подземелье и в замке — разные записи в разных
  каталогах. Ни алиасов, ни глобального реестра, ни префиксов в именах.
- **Анимация декораций нужна сразу.** Кадр — всегда список, статичная декорация
  это список из одного элемента. Отдельной формы записи для статики нет.
- **Стили и уровни только свои, из бандла.** Файлы обновляются вместе с кодом,
  ситуации «новый код читает старый файл» не существует. Значит: строгий разбор,
  никаких миграций, ошибка в файле — баг сборки, а не ситуация у игрока.
- **Игрок, враги, награды, HUD стиля не имеют.** Эта граница проводится явно и
  записывается в CLAUDE.md, иначе размоется на третьем стиле.

## Правило: закрытые типы и открытые идентификаторы

> Если код на этом **ветвится** — закрытый `enum`. Если от этого зависит
> **только картинка** — открытый идентификатор.

| Остаются закрытыми | Становятся открытыми |
| --- | --- |
| `EnemyKind` — `movementStyle`, `weapon`, `defeatPoints` | `DecorationKind` → `DecorationID` |
| `HazardKind` — урон, интервал, глубина | раскладки декораций → каталог стиля |
| `PickupKind`, `CoinTier` — `event`, `staysCollectedAfterDeath` | имена текстур ландшафта → поля каталога |
| `BackgroundFill`, `HorizonSegment`, `SkySegment` | сам стиль → `LevelStyleID` |
| новый `DecorationLayer` — выбор из того, что умеет код | |

За `DecorationKind` не стоит ничего, кроме раскладки плиток: `DecorationTiles` —
это `switch` из 18 веток, каждая возвращает данные. Ни сцена, ни правила на вид
декорации не смотрят. `enum` здесь не защищает ничего — он только мешает стилю
иметь свой набор.

## Куда что переезжает

Четыре слоя, границы те же, что и в остальном проекте: модель ничего не знает
про SpriteKit, ресурсы — про узлы, узлы получают всё снаружи.

```
// Модель — чистые данные, без SpriteKit
LevelConfiguration.style: LevelStyleID
DecorationDescriptor { id: DecorationID, origin: TileCoordinate }
LevelValidation.issues(in:catalog:) -> [Issue]
        |
        v
// Ресурсы — чистые строки, тестируется без SpriteKit
StyleCatalog { terrain, background, skyColor, decorations: [DecorationID: Entry] }
        |
        v
// Ресурсы — SpriteKit, но не узел
LevelTextures { atlas, catalog } -> SKTexture
        |
        v
// Сцена
LevelBuilder(textures:) -> Decoration / Platform / Ladder / Background / Ground
```

Главное следствие: **статические атласы из узлов исчезают**. Сейчас
`SKTextureAtlas(named: "Grassland")` лежит в четырёх местах — `LevelBuilder`,
`Ladder`, `PlatformSkin`, `Hazard`, — и переопределить их снаружи нельзя. Это
скрытое глобальное состояние, и именно оно, а не `TextureName`, — главный стопор.

---

## Шаг 1. Открытый каталог декораций

Самый крупный шаг и единственный, который трогает описания уровней. Арт не
меняется, декорации переезжают один в один.

### Новые типы

```swift
// Model/DecorationID.swift — паттерн Notification.Name
struct DecorationID: RawRepresentable, Hashable, Sendable {
    let rawValue: String
    init(_ rawValue: String) { self.rawValue = rawValue }
    init(rawValue: String) { self.rawValue = rawValue }

    // Имена для кода и тестов; уровни ссылаются строками из файла.
    static let purpleFlower = DecorationID("flower_purple")
    static let darkTree     = DecorationID("tree_dark")
}

// Model/LevelStyleID.swift
struct LevelStyleID: RawRepresentable, Hashable, Sendable {
    let rawValue: String
    static let grassland = LevelStyleID(rawValue: "grassland")
}
```

### Каталог стиля

```swift
// Resources/StyleCatalog.swift — чистые данные, без SpriteKit
struct StyleCatalog: Equatable, Sendable {
    let id: LevelStyleID
    let tilesAtlas: String            // имя .spriteatlas
    let terrain: TerrainNames         // обязательные механические роли
    let background: BackgroundNames
    let skyColor: RGBColor            // = цвет заливки фона
    let decorations: [DecorationID: DecorationEntry]
}

struct TerrainNames: Equatable, Sendable {
    let groundTop: String
    let platformLeft, platformMiddle, platformRight: String
    let ladderBottom, ladderMiddle: String
    let ladderTop: String              // 100 %
    let ladderTop75, ladderTop50, ladderTop25: String
}

struct DecorationEntry: Equatable, Sendable {
    let tiles: [DecorationTile]
    let frameDuration: TimeInterval   // одна на запись — плитки идут в такт
    let randomizePhase: Bool          // два факела рядом не мигают синхронно
    let layer: DecorationLayer

    var isAnimated: Bool { tiles.contains { $0.frames.count > 1 } }
}

struct DecorationTile: Equatable, Sendable {
    let column: Int
    let row: Int
    let frames: [String]              // один кадр = статичная плитка
}

enum DecorationLayer: String, Equatable, Sendable { case back, front }
```

**`frameDuration` — на запись, а не на плитку.** Многоплиточная анимация
(костёр 1×2, водопад) обязана идти в такт, и единственный способ это
гарантировать — одна длительность на всех. То же правило уже действует у озёр.

**`layer` — `enum`, а не число.** Факел на стене рисуется перед игроком, куст —
за ним. Данные выбирают из того, что умеет код; иначе через полгода в файлах
будут магические `zPosition: 47`.

### Переезд

- `DecorationTiles.swift` удаляется целиком; его 18 веток становятся 18 записями
  в `GrasslandCatalog` (пока Swift-литерал).
- `DecorationDescriptor.kind` → `.id`; в `Levels.swift` правится ~40 строк
  расстановки.
- `LevelConfiguration` получает `let style: LevelStyleID`.
- `PlatformTiling` и `LadderTiling` перестают возвращать **имена текстур** и
  возвращают **части** (`.left / .middle / .right`,
  `.bottom / .middle / .top(fraction:)`). Имя из части достаёт `LevelTextures` по
  каталогу. Сейчас эти два типа — чистая логика, но с зашитыми именами
  конкретного стиля.

**Проверка.** Игра выглядит ровно как прежде. Существующие тесты компилируются
без правок, кроме тех, что упоминают `DecorationKind`. Новый тест: у каждой
записи каталога все плитки имеют одинаковое число кадров.

## Шаг 2. Анимация и слой декораций

Узел остаётся тупым: спрайты и готовые `SKAction` приходят снаружи, про каталог
`Decoration` не знает ничего.

```swift
// Nodes/Decoration.swift
final class Decoration: SKNode {
    init(tiles: [SKSpriteNode], layer: DecorationLayer) {
        super.init()
        zPosition = layer == .back ? ZPosition.decorationBack
                                   : ZPosition.decorationFront
        tiles.forEach(addChild)
    }
}

// Scenes/LevelBuilder.swift — фаза, чтобы факелы не мигали в унисон
private func animate(_ sprite: SKSpriteNode,
                     frames: [SKTexture],
                     frameDuration: TimeInterval,
                     randomizePhase: Bool) {
    guard frames.count > 1 else { return }
    let loop = SKAction.repeatForever(
        .animate(with: frames, timePerFrame: frameDuration))
    let period = frameDuration * Double(frames.count)
    let phase = randomizePhase ? Double.random(in: 0..<period) : 0
    sprite.run(.sequence([.wait(forDuration: phase), loop]))
}
```

`ZPosition.decoration` (`-20`) распадается на `decorationBack = -20` и
`decorationFront = 3` — выше игрока (`0`), но ниже жидкости (`5`), чтобы факел
не всплывал поверх лавы.

**Проверка.** Временная запись каталога с двумя кадрами: плитка анимируется, два
экземпляра рядом идут вразнобой, `layer: front` рисуется поверх игрока.

## Шаг 3. Тема вместо статических атласов

Чисто структурный шаг: ни одна картинка не меняется, но появляется место, куда
можно подставить второй стиль.

```swift
// Resources/LevelTextures.swift — SpriteKit, но не узел
@MainActor
struct LevelTextures {
    let catalog: StyleCatalog
    private let atlas: SKTextureAtlas

    init(catalog: StyleCatalog)

    func texture(named: String) -> SKTexture
    func groundTop() -> SKTexture
    func platform(_ part: PlatformTiling.Part) -> SKTexture
    func ladder(_ part: LadderTiling.Part) -> SKTexture
    func decoration(_ id: DecorationID) -> DecorationEntry?
    var skyColor: SKColor { get }

    static func preload(_ catalog: StyleCatalog) async
}

// Scenes/LevelBuilder.swift: enum со статикой → структура с темой
@MainActor
struct LevelBuilder {
    let textures: LevelTextures

    func makeGroundCover(span: ClosedRange<CGFloat>) -> [SKSpriteNode]
    func makeDecoration(from d: DecorationDescriptor) -> Decoration?  // nil = нет в каталоге
    func makePlatform(from d: PlatformDescriptor) -> Platform
    func makeLadder(from d: LadderDescriptor) -> Ladder
    func makeBackground(from c: LevelConfiguration) -> Background
    // makeEnemy / makePickup / makeProjectile темы не требуют — стиля у них нет
}
```

- `PlatformSkin` и `Ladder` получают текстуры параметром вместо своего
  `SKTextureAtlas`.
- `ScenePalette.sky` исчезает: цвет неба переезжает в `StyleCatalog.skyColor`. Он
  **обязан** совпадать с заливкой фона — у фоновых картинок края залиты тем же
  цветом, иначе станет виден их прямоугольник.
- `GameScene.init` создаёт `LevelTextures` по `configuration.style` и держит
  `LevelBuilder` полем.
- `TextureName` остаётся, но худеет до нестилевого: игрок, враги, снаряд,
  награды, флаг.

**Проверка.** Полное визуальное совпадение с прежней сборкой. Все существующие
тесты зелёные.

## Шаг 4. Валидация вместо компилятора

Открытый идентификатор отнимает у компилятора возможность ловить опечатки.
Замена — чистая функция и тест, который прогоняет через неё всё, что лежит в
проекте.

```swift
// Model/LevelValidation.swift — чистая, тестируется без SpriteKit
enum LevelValidation {

    enum Issue: Equatable {
        case unknownDecoration(DecorationID, at: TileCoordinate)
        case frameCountMismatch(DecorationID)
        case emptyTextureName(role: String)
        case objectOutsideLevel(role: String, at: TileCoordinate)
        case checkpointWithoutFooting(index: Int)
    }

    /// Проверки самого каталога — не зависят от уровня.
    static func issues(in catalog: StyleCatalog) -> [Issue]

    /// Проверки уровня против каталога его стиля.
    static func issues(in level: LevelConfiguration,
                       catalog: StyleCatalog) -> [Issue]
}
```

Политика разная по категориям — и это не мелочь, а решение о том, что считается
фатальным:

- **Механическая роль пуста** → уровень не собирается. Без плитки платформы
  играть нельзя.
- **Незнакомая декорация** → в DEBUG `assertionFailure` (автор видит опечатку
  сразу), в релизе пропуск с записью в лог. Терять уровень из-за лишнего
  цветочка нельзя.

Поверх — интеграционный тест: пройти по всем стилям и всем их записям и
убедиться, что каждая названная текстура есть в атласе
(`SKTextureAtlas.textureNames`).

> **Исключение из конвенции.** Этот тест требует SpriteKit и потому выпадает из
> правила «тесты покрывают только модель». Исключение оправданное, но его надо
> **записать в CLAUDE.md** — иначе следующая уборка удалит его как не
> соответствующий конвенции.

**Проверка.** Умышленно испорченный каталог (опечатка в имени, разное число
кадров) валит тест с внятным `Issue`, а не розовым квадратом в игре.

## Шаг 5. Второй стиль — момент истины

Первый шаг, который что-то меняет на экране, и единственная настоящая проверка
всей конструкции. Брать надо стиль с **заведомо другим** набором декораций —
подземелье с факелами и бочками, а не «луг, но осенью»: одинаковые наборы ничего
не проверят.

- `Assets.xcassets/Tiles/Dungeon.spriteatlas` + `Background/` для его слоёв.
- `DungeonCatalog` — свои 6–8 декораций, из них 2–3 анимированные.
- Один уровень в `Levels.swift` переводится на новый стиль целиком.

> **Ловушка ассетов.** Папки в `.xcassets` — **не** пространства имён, если не
> включено «Provides Namespace». Фон читается через `SKTexture(imageNamed:)`,
> поэтому `bg_hills` в двух стилях просто столкнутся. Варианты: префиксовать
> имена (`dungeon_bg_hills`), включить namespace на папке (доступ станет
> `Dungeon/bg_hills`) или перевести фон в атлас-на-стиль. У плиточных атласов
> такой проблемы нет — атлас сам себе пространство имён.

> **Ловушка памяти.** Сейчас атласы лежат в `static let` и живут вечно. При 5–10
> стилях это утечка по нарастающей: нужен `preload` нужного атласа перед показом
> сцены (иначе рывок на первом кадре) и отпускание предыдущего при смене уровня.

**Проверка.** Уровень играется в новом стиле; переключение стиля в описании
уровня — правка одного поля; в коде для этого не меняется ничего.

## Шаг 6. Уровни и каталоги из файлов

Отделён намеренно: формат проектируется по уже работающей модели, а не наоборот.
Начать с JSON — значит зафиксировать в формате сегодняшние представления о
стилях и версионировать его с первой недели.

### Формат ≠ модель

```swift
// Levels/LevelFile.swift — DTO, строгий Decodable
struct LevelFile: Decodable {
    let formatVersion: Int
    let id: String            // стабильный, не позиция в папке
    let revision: Int         // растёт при правке геометрии
    let style: String
    // … остальное — авторский, а не вычислительный вид
}

// Levels/LevelLoader.swift
enum LevelLoader {
    enum Failure: Error {
        case unsupportedVersion(Int)
        case unknownStyle(String)
        case invalid([LevelValidation.Issue])
    }
    static func loadAll() throws -> [LevelConfiguration]
}
```

Две структуры вместо одной — не дублирование: в файле хочется `"at": [12, 1]` и
опущенные поля, в модели — именованный `TileCoordinate` и всё обязательное.
Кроме того, синтезированный `Codable` сделал бы модель заложницей формата — ровно
та ловушка, что уже описана у `GameProgress`.

### Стабильные строковые id

`EnemyKind`, `HazardKind`, `CoinTier`, `HorizonSegment`, `SkySegment` получают
явные `String` raw values (`case sniper = "sniper"`) — **никогда** выводимые из
имени case автоматически, иначе переименование в Swift молча ломает все файлы.

> **Без этого шаг бессмыслен.** Уровни в бандле правятся с той же пересборкой,
> что и `Levels.swift`. В таком виде переход на файлы **не даёт ускорения**, а
> компилятор теряется — чистый минус.
>
> Выигрыш появляется вместе с перезагрузкой без пересборки: в DEBUG грузить не из
> бандла, а из папки исходников (путь берётся из `#filePath`) и перечитывать файл
> по «начать уровень заново». Цикл «поправил координату — увидел» становится
> секундным. В RELEASE — бандл. Один `#if DEBUG` в загрузчике, но заложить надо
> сразу, иначе к этому моменту `GameScene` уже жёстко берёт `Levels.all[index]`.

> **Индексы в сохранении.** `GameProgress` хранит `currentLevelIndex`,
> `activeCheckpointIndex`, `collectedPickupIndices`, `defeatedEnemyIndices` — всё
> это позиции в массивах `LevelConfiguration`. Проблема не новая: сдвинуть флаг в
> `Levels.swift` и выпустить обновление можно и сегодня. Но файлы делают правку
> уровня дешёвой, и то, что случалось раз в релиз, начнёт случаться постоянно.
>
> Минимум: строковый `id` уровня вместо позиции в папке и `revision` в
> сохранении. Не совпала — прогресс по уровню начинается заново, вместо
> применения старых индексов к новой геометрии. Поле обязано быть необязательным
> (`var levelRevision: Int? = nil`): синтезированный `Codable` не подставляет
> умолчание, и обязательный ключ сделал бы нечитаемыми сохранения прошлых сборок.

Один уровень остаётся зашитым в код как фикстура, чтобы модельные тесты не
зависели от файлового ввода-вывода и от содержимого бандла.

**Проверка.** Правка координаты в JSON видна после перезапуска уровня без
пересборки. Испорченный файл валит тест загрузки всех уровней, а не игру у
игрока.

---

## Что происходит с каждым файлом

| Файл | Шаг | | Что происходит |
| --- | --- | --- | --- |
| `Model/DecorationID.swift` | 1 | нов | Открытый идентификатор вместо `enum` |
| `Model/LevelStyleID.swift` | 1 | нов | Идентификатор стиля |
| `Model/LevelConfiguration.swift` | 1 | правка | `+ style`; `DecorationDescriptor.kind → id`; `DecorationKind` удаляется |
| `Model/LevelValidation.swift` | 4 | нов | Чистые проверки каталога и уровня |
| `Resources/StyleCatalog.swift` | 1 | нов | Каталог стиля: роли, декорации, цвет |
| `Resources/Styles/GrasslandCatalog.swift` | 1 | нов | Нынешний арт как данные |
| `Resources/Styles/DungeonCatalog.swift` | 5 | нов | Второй стиль |
| `Resources/DecorationTiles.swift` | 1 | удал | Переезжает в каталоги |
| `Resources/TextureName.swift` | 3 | правка | Худеет до нестилевого: игрок, враги, награды |
| `Resources/PlatformTiling.swift` | 1 | правка | Возвращает части, а не имена текстур |
| `Levels/LadderTiling.swift` | 1 | правка | То же для лестницы |
| `Resources/LevelTextures.swift` | 3 | нов | Атласы + разрешение имён, `preload` |
| `Nodes/Decoration.swift` | 2 | правка | `+ layer`, анимированные плитки |
| `Nodes/ZPosition.swift` | 2 | правка | `decoration` → `decorationBack` / `decorationFront` |
| `Nodes/PlatformSkin.swift` | 3 | правка | Атлас снаружи |
| `Nodes/Ladder.swift` | 3 | правка | Атлас снаружи |
| `Nodes/Background.swift` | 3 | правка | Имена слоёв и цвет из каталога |
| `Nodes/ScenePalette.swift` | 3 | удал | `sky` переезжает в каталог |
| `Scenes/LevelBuilder.swift` | 3 | правка | `enum` со статикой → структура с темой |
| `Scenes/GameScene.swift` | 3 | правка | Создаёт `LevelTextures`, держит билдер |
| `Scenes/MainMenuScene.swift` | 6 | правка | `Levels.all` → загруженный каталог уровней |
| `Scenes/VictoryScene.swift` | 6 | правка | То же |
| `Levels/Levels.swift` | 1, 5, 6 | правка | `+ style`; затем один уровень остаётся фикстурой |
| `Levels/LevelFile.swift` | 6 | нов | DTO формата |
| `Levels/LevelLoader.swift` | 6 | нов | Разбор, валидация, DEBUG-перезагрузка |
| `Model/GameProgress.swift` | 6 | правка | `+ levelRevision: Int?` |

## Что в план не входит

- **Стиль игрока, врагов, наград и HUD.** Их атласы остаются в узлах как есть —
  это осознанная граница, а не недоделка.
- **Переносимость уровня между стилями.** Уровень привязан к своему стилю; «тот
  же уровень в снегу» = переписать список декораций.
- **Редактор уровней и пользовательские файлы.** Формат проектируется под свои
  файлы: строгий разбор, без защиты от враждебного ввода.
- **Миграции формата.** Файлы обновляются вместе с кодом. `formatVersion`
  заводится как ловушка, кода миграции за ним нет.
- **Поведение декораций** (свет от факела, разбиваемая бочка). Если понадобится —
  это маленький закрытый `enum DecorationBehavior` с умолчанием `none`: данные
  выбирают из реализованного, но не описывают поведение сами. Как только каталог
  начнёт описывать поведение, он превратится в скриптовый движок.
