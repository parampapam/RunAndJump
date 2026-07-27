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
    /// Спрайты наград (атлас Pickups) рисуют объект в центральной половине
    /// кадра, остальное — прозрачные поля. Узел — целый тайл, чтобы видимая
    /// часть была ~полтайла; хитбокс — по видимой части, а не по полям.
    static let pickup = TileSize.one
    static let pickupHitbox = TileSize(width: 0.5, height: 0.5)
    static let portal = TileSize(width: 0.75, height: 1.5)
    static let ladder = TileSize(width: 0.75, height: 1)
    /// Снаряд снайпера. Спрайт, как и награды, нарисован в центре кадра с
    /// прозрачными полями: узел в полтайла даёт шарик примерно в четверть тайла.
    static let projectile = TileSize(width: 0.5, height: 0.5)
    /// Радиус хитбокса снаряда, тайлы — по видимому шарику, а не по полям кадра.
    static let projectileHitboxRadius: CGFloat = 0.14
}
