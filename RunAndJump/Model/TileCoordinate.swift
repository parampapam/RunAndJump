//
//  TileCoordinate.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 21.06.2026.
//

import CoreGraphics

/// Координата на тайловой сетке. Дробные значения допустимы — для смещения
/// объекта от сетки (например, поставить лестницу между двумя клетками).
/// Перевод в пункты сцены делает `Grid`.
struct TileCoordinate: Equatable {
    var x: CGFloat
    var y: CGFloat
}

/// Размер в тайлах.
struct TileSize: Equatable {
    var width: CGFloat
    var height: CGFloat

    static let one: TileSize = .init(width: 1, height: 1)
}

/// Прямоугольник на сетке, заданный **нижним-левым углом** и размером (в тайлах).
/// Удобно для протяжённых объектов: указываешь, где стоит угол, а не центр.
struct TileRect: Equatable {
    var origin: TileCoordinate   // нижний-левый угол
    var size: TileSize
}
