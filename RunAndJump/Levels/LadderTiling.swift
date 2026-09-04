//
//  LadderTiling.swift
//  RunAndJump
//

import CoreGraphics

/// Раскладка лестницы по тайлам — снизу вверх: нижняя плитка, ноль и более
/// средних, верхняя. Чистая логика, без SpriteKit: `Ladder` (узел) только
/// строит из неё спрайты.
///
/// Возвращает **части**, а не имена текстур — по той же причине, что и
/// `PlatformTiling`: раскладка общая на все стили, картинка у каждого своя.
///
/// Ширина лестницы всегда одна (`ObjectSize.ladder.width`), поэтому здесь
/// участвует только высота (в тайлах). Текстур для верхней плитки всего
/// четыре — 100/75/50/25% тайла, — поэтому итоговая высота **округляется
/// вверх** до ближайшей из них: лестница всегда достаёт до опоры сверху,
/// а не обрывается чуть ниже. Итоговая (возможно округлённая) высота —
/// единственный источник истины для размера и положения узла `Ladder`.
enum LadderTiling {

    /// Роль плитки в лестнице. Имя текстуры по ней даёт каталог стиля.
    ///
    /// У верхней плитки — доля тайла, которую она занимает: стиль обязан иметь
    /// картинку на каждую из четырёх долей (1, 0.75, 0.5, 0.25).
    enum Part: Equatable, Sendable {
        case bottom
        case middle
        case top(fraction: CGFloat)
    }

    /// Одна плитка лестницы: высота в тайлах (0, 1] и её роль.
    struct Tile: Equatable, Sendable {
        let heightInTiles: CGFloat
        let part: Part
    }

    /// Раскладка лестницы под запрошенную высоту (в тайлах, > 0).
    static func layout(forRequestedHeightInTiles height: CGFloat) -> (tiles: [Tile], totalHeightInTiles: CGFloat) {
        precondition(height > 0, "Высота лестницы должна быть положительной")

        // Меньше одного тайла не бывает — лестница из одной (нижней) плитки.
        guard height > 1 else {
            let tile = Tile(heightInTiles: 1, part: .bottom)
            return ([tile], tile.heightInTiles)
        }

        let wholeTiles = Int(height)
        let remainder = height - CGFloat(wholeTiles)
        let top = topTile(forRemainder: remainder)
        // Остаток 0 — высота кратна тайлу, последний целый тайл сам и есть верх (100%).
        let middleCount = remainder == 0 ? wholeTiles - 2 : wholeTiles - 1

        var tiles = [Tile(heightInTiles: 1, part: .bottom)]
        tiles += Array(repeating: Tile(heightInTiles: 1, part: .middle),
                       count: max(0, middleCount))
        tiles.append(top)

        return (tiles, tiles.reduce(0) { $0 + $1.heightInTiles })
    }

    /// Подбирает верхнюю плитку под остаток деления высоты на тайл.
    private static func topTile(forRemainder remainder: CGFloat) -> Tile {
        switch remainder {
        case 0:
            return Tile(heightInTiles: 1, part: .top(fraction: 1))
        case ...0.25:
            return Tile(heightInTiles: 0.25, part: .top(fraction: 0.25))
        case ...0.5:
            return Tile(heightInTiles: 0.5, part: .top(fraction: 0.5))
        case ...0.75:
            return Tile(heightInTiles: 0.75, part: .top(fraction: 0.75))
        default:
            return Tile(heightInTiles: 1, part: .top(fraction: 1))
        }
    }
}
