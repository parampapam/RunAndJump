//
//  DecorationTiles.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.06.2026.
//

import Foundation

/// Одна плитка составной декорации: ячейка в сетке декорации (смещение в тайлах
/// от нижнего-левого угла) и имя её текстуры. Плитка занимает ровно один тайл.
struct DecorationTile: Equatable {
    let column: Int
    let row: Int
    let textureName: String
}

/// Раскладка плиток для каждого вида декорации. Декорация может занимать
/// несколько тайлов, и у каждого — своя текстура: дерево разное снизу и сверху,
/// куст — по горизонтали. Габарит объекта неявно задаётся набором плиток.
enum DecorationTiles {
    static func tiles(for kind: DecorationKind) -> [DecorationTile] {
        switch kind {
        case .purpleFlower:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Flower.purple)]
        case .yellowFlower:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Flower.yellow)]
        case .whiteFlower:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Flower.white)]
        case .pinkFlower:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Flower.pink)]
        case .darkTree:
            return [
                DecorationTile(column: 0, row: 0, textureName: TextureName.Tree.Dark.bottom),
                DecorationTile(column: 0, row: 1, textureName: TextureName.Tree.Dark.top),
            ]
        case .tallDarkTree:
            return [
                DecorationTile(column: 0, row: 0, textureName: TextureName.Tree.Dark.trunk),
                DecorationTile(column: 0, row: 1, textureName: TextureName.Tree.Dark.bottom),
                DecorationTile(column: 0, row: 2, textureName: TextureName.Tree.Dark.top),
            ]
        case .lightTree:
                return [
                    DecorationTile(column: 0, row: 0, textureName: TextureName.Tree.Light.bottom),
                    DecorationTile(column: 0, row: 1, textureName: TextureName.Tree.Light.top),
                ]
        case .tallLightTree:
                return [
                    DecorationTile(column: 0, row: 0, textureName: TextureName.Tree.Light.trunk),
                    DecorationTile(column: 0, row: 1, textureName: TextureName.Tree.Light.bottom),
                    DecorationTile(column: 0, row: 2, textureName: TextureName.Tree.Light.top),
                ]
        case .bigDarkBush:
            return [
                DecorationTile(column: 0, row: 0, textureName: TextureName.Bush.Big.Dark.left),
                DecorationTile(column: 1, row: 0, textureName: TextureName.Bush.Big.Dark.middle),
                DecorationTile(column: 2, row: 0, textureName: TextureName.Bush.Big.Dark.right),
            ]
        case .bigLightBush:
            return [
                DecorationTile(column: 0, row: 0, textureName: TextureName.Bush.Big.Light.left),
                DecorationTile(column: 1, row: 0, textureName: TextureName.Bush.Big.Light.middle),
                DecorationTile(column: 2, row: 0, textureName: TextureName.Bush.Big.Light.right),
            ]
        case .smallDarkBush:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Bush.Small.dark)]
        case .smallLightBush:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Bush.Small.light)]
        case .leftArrow:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Arrow.left)]
        case .rightArrow:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Arrow.right)]
        case .shortLightGrass:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Grass.Short.light)]
        case .shortDarkGrass:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Grass.Short.dark)]
        case .tallLightGrass:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Grass.Tall.light)]
        case .tallDarkGrass:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Grass.Tall.dark)]
        }
    }
}
