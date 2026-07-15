//
//  ObjectSize.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 21.06.2026.
//

import CoreGraphics

/// Размеры объектов, габариты которых всегда одинаковы. Единый источник —
/// и для размера узла, и для вычисления центра из нижнего-левого угла. В тайлах.
enum ObjectSize {
    static let player = TileSize.one
    static let enemy  = TileSize(width: 0.75, height: 0.75)
    static let pickup = TileSize(width: 0.5, height: 0.5)
    static let portal = TileSize(width: 0.75, height: 1.5)
    static let ladder = TileSize(width: 0.75, height: 1)
}
