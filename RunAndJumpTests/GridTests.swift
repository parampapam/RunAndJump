//
//  GridTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 21.06.2026.
//

import Testing
import CoreGraphics
@testable import RunAndJump

@Suite("Grid — тайлы в пункты")
struct GridTests {

    private let tile = WorldMetrics.tileSize  // 60

    @Test("Целая тайловая координата переводится в пункты умножением на размер тайла")
    func pointFromWholeTiles() {
        let p = Grid.point(TileCoordinate(x: 3, y: 2))
        #expect(p.x == 3 * tile)
        #expect(p.y == 2 * tile)
    }

    @Test("Дробная координата даёт смещение от сетки")
    func pointFromFractionalTiles() {
        let p = Grid.point(TileCoordinate(x: 1.5, y: 0.25))
        #expect(p.x == 1.5 * tile)
        #expect(p.y == 0.25 * tile)
    }

    @Test("Тайл (0,0) — это точка (0,0)")
    func originMapsToZero() {
        let p = Grid.point(TileCoordinate(x: 0, y: 0))
        #expect(p == .zero)
    }

    @Test("Размер в тайлах переводится в пункты")
    func sizeFromTiles() {
        let s = Grid.size(TileSize(width: 3, height: 0.25))
        #expect(s.width == 3 * tile)
        #expect(s.height == 0.25 * tile)
    }

    @Test("Центр считается от нижнего-левого угла плюс половина размера")
    func centerFromOriginAndSize() {
        let c = Grid.center(origin: TileCoordinate(x: 5, y: 2.75),
                            size: TileSize(width: 3, height: 0.25))
        // Угол (5, 2.75) тайла + половина (3, 0.25) тайла.
        #expect(c.x == (5 + 3.0 / 2) * tile)
        #expect(c.y == (2.75 + 0.25 / 2) * tile)
    }

    @Test("center(of:) согласован с center(origin:size:)")
    func centerOfRectMatchesOriginSize() {
        let rect = TileRect(origin: TileCoordinate(x: 4, y: 1),
                            size: TileSize(width: 2, height: 0.25))
        #expect(Grid.center(of: rect) == Grid.center(origin: rect.origin, size: rect.size))
    }

    @Test("Нижний-левый угол объекта на земле (y=1) лежит на верхе земли")
    func objectOnGroundSitsOnGroundTop() {
        // Земля высотой 1 тайл → её верх на y = 1 тайл = tile пунктов.
        let originY = Grid.point(TileCoordinate(x: 0, y: 1)).y
        #expect(originY == Levels.groundHeight)
    }
}
