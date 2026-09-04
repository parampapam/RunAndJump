//
//  PlatformSkin.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 06.08.2026.
//

import SpriteKit

/// Оформление платформы: ряд плиток по раскладке `PlatformTiling`. Общий вид для неподвижной (`Platform`) и подвижной
/// (`MovingPlatform`) — отличаются они только движением, не внешностью.
///
/// Плитки чисто визуальные: коллизия — на верхнем ребре самого узла
/// (односторонняя платформа). Нарисованная планка занимает **верхнюю половину**
/// квадратного кадра, поэтому плитка кладётся размером в тайл и выравнивается
/// **по верхнему краю** узла: планка ложится ровно на линию, по которой стоит
/// игрок, а её видимая толщина не зависит от толщины физического ребра.
@MainActor
enum PlatformSkin {

    /// Плитки для платформы заданного размера (в пунктах), спозиционированные
    /// относительно центра узла. Текстуры приходят темой уровня: раскладка
    /// (`PlatformTiling`) общая на все стили, картинки — свои у каждого.
    static func tiles(forSize size: CGSize, textures: LevelTextures) -> [SKSpriteNode] {
        let parts = PlatformTiling.parts(forWidthInTiles: size.width / WorldMetrics.tileSize)
        let cellWidth = size.width / CGFloat(parts.count)
        let tileSize = CGSize(width: cellWidth, height: WorldMetrics.tileSize)

        return parts.enumerated().map { column, part in
            let tile = SKSpriteNode(texture: textures.platform(part), size: tileSize)
            tile.position = CGPoint(
                x: -size.width / 2 + cellWidth * (CGFloat(column) + 0.5),
                y: size.height / 2 - tileSize.height / 2
            )
            return tile
        }
    }
}
