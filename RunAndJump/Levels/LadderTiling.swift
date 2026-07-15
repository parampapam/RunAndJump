//
//  LadderTiling.swift
//  RunAndJump
//

import CoreGraphics

/// Раскладка лестницы по тайлам — снизу вверх: нижняя плитка, ноль и более
/// средних, верхняя. Чистая логика, без SpriteKit: `Ladder` (узел) только
/// строит из неё спрайты.
///
/// Ширина лестницы всегда одна (`ObjectSize.ladder.width`), поэтому здесь
/// участвует только высота (в тайлах). Текстур для верхней плитки всего
/// четыре — 100/75/50/25% тайла, — поэтому итоговая высота **округляется
/// вверх** до ближайшей из них: лестница всегда достаёт до опоры сверху,
/// а не обрывается чуть ниже. Итоговая (возможно округлённая) высота —
/// единственный источник истины для размера и положения узла `Ladder`.
enum LadderTiling {

    /// Одна плитка лестницы: высота в тайлах (0, 1] и имя текстуры.
    struct Tile: Equatable {
        let heightInTiles: CGFloat
        let textureName: String
    }

    /// Раскладка лестницы под запрошенную высоту (в тайлах, > 0).
    static func layout(forRequestedHeightInTiles height: CGFloat) -> (tiles: [Tile], totalHeightInTiles: CGFloat) {
        precondition(height > 0, "Высота лестницы должна быть положительной")

        // Меньше одного тайла не бывает — лестница из одной (нижней) плитки.
        guard height > 1 else {
            let tile = Tile(heightInTiles: 1, textureName: TextureName.Ladder.bottom)
            return ([tile], tile.heightInTiles)
        }

        let wholeTiles = Int(height)
        let remainder = height - CGFloat(wholeTiles)
        let top = topTile(forRemainder: remainder)
        // Остаток 0 — высота кратна тайлу, последний целый тайл сам и есть верх (100%).
        let middleCount = remainder == 0 ? wholeTiles - 2 : wholeTiles - 1

        var tiles = [Tile(heightInTiles: 1, textureName: TextureName.Ladder.bottom)]
        tiles += Array(repeating: Tile(heightInTiles: 1, textureName: TextureName.Ladder.middle),
                       count: max(0, middleCount))
        tiles.append(top)

        return (tiles, tiles.reduce(0) { $0 + $1.heightInTiles })
    }

    /// Подбирает текстуру верхней плитки под остаток деления высоты на тайл.
    private static func topTile(forRemainder remainder: CGFloat) -> Tile {
        switch remainder {
        case 0:
            return Tile(heightInTiles: 1, textureName: TextureName.Ladder.up)
        case ...0.25:
            return Tile(heightInTiles: 0.25, textureName: TextureName.Ladder.up_25pct)
        case ...0.5:
            return Tile(heightInTiles: 0.5, textureName: TextureName.Ladder.up_50pct)
        case ...0.75:
            return Tile(heightInTiles: 0.75, textureName: TextureName.Ladder.up_75pct)
        default:
            return Tile(heightInTiles: 1, textureName: TextureName.Ladder.up)
        }
    }
}
