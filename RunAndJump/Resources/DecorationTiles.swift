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
        case .flower1:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Ground.flower1)]
        case .flower2:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Ground.flower2)]
        case .flower3:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Ground.flower3)]
        case .flower4:
            return [DecorationTile(column: 0, row: 0, textureName: TextureName.Ground.flower4)]
        case .tree:
            // 1 тайл в ширину, 2 в высоту: низ (ствол) и верх (крона).
            return [
                DecorationTile(column: 0, row: 0, textureName: TextureName.Ground.treeBottom),
                DecorationTile(column: 0, row: 1, textureName: TextureName.Ground.treeTop),
            ]
        case .bush:
            // 3 тайла в ширину, 1 в высоту.
            return [
                DecorationTile(column: 0, row: 0, textureName: TextureName.Ground.bushLeft),
                DecorationTile(column: 1, row: 0, textureName: TextureName.Ground.bushMiddle),
                DecorationTile(column: 2, row: 0, textureName: TextureName.Ground.bushRight),
            ]
        }
    }
}
