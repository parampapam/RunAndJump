//
//  StyleCatalog.swift
//  RunAndJump
//

import CoreGraphics
import Foundation

/// Оформление уровня как данные: чем нарисован ландшафт, чем — фон и какие
/// декорации стиль вообще знает.
///
/// Чистые данные, **без SpriteKit**: каталог оперирует именами текстур, а не
/// текстурами. Превращает имена в `SKTexture` слой выше (`LevelTextures`),
/// поэтому каталог тестируется как обычная модель.
///
/// Каталог разделён надвое не случайно:
/// - `terrain` — **механические роли**. Без плитки платформы играть нельзя,
///   поэтому роли обязательны и заданы полями: забыть одну не даст компилятор.
/// - `decorations` — **украшения**. Их набор у каждого стиля свой, поэтому это
///   словарь по открытому `DecorationID`, а не поля.
struct StyleCatalog: Equatable, Sendable {

    let id: LevelStyleID

    /// Атласы, в которых лежат текстуры стиля, в порядке поиска имени.
    ///
    /// Список, а не одно имя: нынешний арт луга разложен по трём атласам
    /// (`Grassland` — земля и декорации, `Platforms`, `Ladder`), и сводить их в
    /// один значило бы двигать ассеты ради формы каталога. Стиль вправе держать
    /// всё в одном атласе — тогда в списке будет один элемент.
    let atlases: [String]

    /// Обязательные роли ландшафта.
    let terrain: TerrainNames

    /// Слои фона.
    let background: BackgroundNames

    /// Цвет фона сцены. Виден там, где нет ни одного спрайта: в первую очередь
    /// на дне ям под озёрами — за жидкостью грунта нет.
    ///
    /// **Обязан совпадать** с цветом заливки `background.fill`: у фоновых
    /// картинок края залиты тем же цветом, и разойдись эти два цвета — станет
    /// виден прямоугольник заливки.
    let skyColor: RGBColor

    /// Украшения стиля. Уровень ссылается на них идентификатором; чего нет в
    /// словаре, того у стиля не существует (см. `LevelValidation`).
    let decorations: [DecorationID: DecorationEntry]
}

/// Имена текстур ландшафта — те роли, без которых уровень не собрать.
struct TerrainNames: Equatable, Sendable {

    /// Верхняя плитка земли (травяное покрытие).
    let groundTop: String

    let platformLeft: String
    let platformMiddle: String
    let platformRight: String

    let ladderBottom: String
    let ladderMiddle: String
    /// Верх лестницы на всю высоту тайла.
    let ladderTop: String
    /// Верх лестницы на 3/4, 1/2 и 1/4 тайла — лестница округляется вверх до
    /// ближайшей из этих четырёх высот (см. `LadderTiling`).
    let ladderTop75: String
    let ladderTop50: String
    let ladderTop25: String

    /// Имя текстуры колонки платформы.
    func name(for part: PlatformTiling.Part) -> String {
        switch part {
        case .left: return platformLeft
        case .middle: return platformMiddle
        case .right: return platformRight
        }
    }

    /// Имя текстуры плитки лестницы.
    func name(for part: LadderTiling.Part) -> String {
        switch part {
        case .bottom: return ladderBottom
        case .middle: return ladderMiddle
        case .top(let fraction): return ladderTop(fraction: fraction)
        }
    }

    /// Верхняя плитка под долю тайла. Доли приходят из `LadderTiling` ровно
    /// четырьмя значениями; всё прочее считается целым тайлом.
    private func ladderTop(fraction: CGFloat) -> String {
        switch fraction {
        case 0.25: return ladderTop25
        case 0.5: return ladderTop50
        case 0.75: return ladderTop75
        default: return ladderTop
        }
    }
}

/// Имена слоёв фона. Поля, а не словарь по сегментам: сегменты фона —
/// закрытые `enum`, и новый сегмент **обязан** сломать сборку каждого каталога,
/// а не тихо остаться ненарисованным.
struct BackgroundNames: Equatable, Sendable {

    /// Сплошная заливка на весь уровень. Её цвет = `StyleCatalog.skyColor`.
    let fill: String
    let hills: String
    let mountains: String
    let clouds: String

    func name(for fill: BackgroundFill) -> String {
        switch fill {
        case .daySky: return self.fill
        }
    }

    /// `nil` — сегмент ничего не рисует, и на его месте видна заливка.
    func name(for segment: HorizonSegment) -> String? {
        switch segment {
        case .hills: return hills
        case .mountains: return mountains
        case .fill: return nil
        }
    }

    func name(for segment: SkySegment) -> String {
        switch segment {
        case .clouds: return clouds
        }
    }
}

/// Одна декорация каталога: из каких плиток собрана, как анимирована и перед
/// игроком она или за ним.
struct DecorationEntry: Equatable, Sendable {

    let tiles: [DecorationTile]

    /// Длительность кадра — **одна на запись**, а не на плитку. Многоплиточная
    /// анимация (костёр 1×2, водопад) обязана идти в такт, и единственный
    /// способ это гарантировать — общая длительность. То же правило уже
    /// действует у озёр (`Hazard`).
    let frameDuration: TimeInterval

    /// Сдвигать ли начало анимации на случайную фазу. Два факела рядом не
    /// должны мигать синхронно; волна на воде, наоборот, обязана идти в такт.
    let randomizePhase: Bool

    let layer: DecorationLayer

    /// - Parameters:
    ///   - frameDuration: для статичной записи значения не имеет.
    init(tiles: [DecorationTile],
         frameDuration: TimeInterval = 0.2,
         randomizePhase: Bool = false,
         layer: DecorationLayer = .back) {
        self.tiles = tiles
        self.frameDuration = frameDuration
        self.randomizePhase = randomizePhase
        self.layer = layer
    }

    var isAnimated: Bool { tiles.contains { $0.frames.count > 1 } }
}

/// Одна плитка составной декорации: ячейка в сетке декорации (смещение в тайлах
/// от нижнего-левого угла) и её кадры. Плитка занимает ровно один тайл.
///
/// Кадр — **всегда список**: статичная плитка это список из одного элемента.
/// Отдельной формы записи для статики нет, иначе каждая обработка декораций
/// раздваивалась бы на «а вдруг она анимированная».
struct DecorationTile: Equatable, Sendable {
    let column: Int
    let row: Int
    let frames: [String]
}

/// Перед игроком декорация или за ним.
///
/// `enum`, а не число: факел на стене рисуется перед игроком, куст — за ним, и
/// это выбор из того, что умеет код. Дай сюда `zPosition` числом — и через
/// полгода в файлах уровней будут магические `47`.
enum DecorationLayer: String, Equatable, Sendable {
    case back
    case front
}

/// Цвет в модельном слое: без SpriteKit, чтобы каталог оставался чистыми
/// данными. В `SKColor` его превращает `LevelTextures`.
struct RGBColor: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
}
