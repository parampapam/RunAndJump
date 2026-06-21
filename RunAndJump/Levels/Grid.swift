//
//  Grid.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 21.06.2026.
//

import CoreGraphics

/// Перевод координат тайловой сетки в пункты сцены.
/// Чистые функции — покрыты тестами. Единица сетки — `WorldMetrics.tileSize`.
/// Все объекты привязываются к **нижнему-левому углу**; центр (которого требует
/// SpriteKit) вычисляется здесь, чтобы узлы оставались центрированными, а их
/// физические тела — без изменений.
enum Grid {
    /// Точка (в пунктах) для тайловой координаты. Тайл (0, 0) → точка (0, 0).
    static func point(_ tile: TileCoordinate) -> CGPoint {
        CGPoint(x: tile.x * WorldMetrics.tileSize, y: tile.y * WorldMetrics.tileSize)
    }

    /// Размер (в пунктах) из размера в тайлах.
    static func size(_ tile: TileSize) -> CGSize {
        CGSize(width: tile.width * WorldMetrics.tileSize,
               height: tile.height * WorldMetrics.tileSize)
    }

    /// Центр (в пунктах) объекта по его нижнему-левому углу и размеру в тайлах.
    static func center(origin: TileCoordinate, size tileSize: TileSize) -> CGPoint {
        let o = point(origin)
        let s = size(tileSize)
        return CGPoint(x: o.x + s.width / 2, y: o.y + s.height / 2)
    }

    /// Центр (в пунктах) прямоугольника на сетке (нижний-левый угол + размер).
    static func center(of rect: TileRect) -> CGPoint {
        center(origin: rect.origin, size: rect.size)
    }
}
