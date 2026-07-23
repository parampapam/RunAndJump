//
//  CameraMathTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
@testable import RunAndJump

@Suite("CameraMath")
struct CameraMathTests {

    @Test("Игрок в середине уровня — камера не клэмпится")
    func centeredTargetIsUnclamped() {
        let position = CameraMath.clampedPosition(
            target: CGPoint(x: 500, y: 300),
            viewportSize: CGSize(width: 400, height: 200),
            levelSize: CGSize(width: 1000, height: 600)
        )
        #expect(position == CGPoint(x: 500, y: 300))
    }

    @Test("Игрок у левого/нижнего края уровня — камера прижата к halfViewport")
    func targetNearOriginClampsToHalfViewport() {
        let position = CameraMath.clampedPosition(
            target: CGPoint(x: 0, y: 0),
            viewportSize: CGSize(width: 400, height: 200),
            levelSize: CGSize(width: 1000, height: 600)
        )
        #expect(position == CGPoint(x: 200, y: 100))
    }

    @Test("Игрок у правого/верхнего края уровня — камера прижата к levelSize - halfViewport")
    func targetNearFarEdgeClampsToLevelBound() {
        let position = CameraMath.clampedPosition(
            target: CGPoint(x: 1000, y: 600),
            viewportSize: CGSize(width: 400, height: 200),
            levelSize: CGSize(width: 1000, height: 600)
        )
        #expect(position == CGPoint(x: 800, y: 500))
    }

    @Test("Уровень уже видимой области — клэмп инвертирован, камера прижата к halfViewport")
    func levelSmallerThanViewportPinsToHalfViewport() {
        let position = CameraMath.clampedPosition(
            target: CGPoint(x: 150, y: 100),
            viewportSize: CGSize(width: 400, height: 200),
            levelSize: CGSize(width: 300, height: 150)
        )
        // halfW = 200, levelWidth - halfW = 100 < halfW → max победил, x = 200.
        // halfH = 100, levelHeight - halfH = 50 < halfH → max победил, y = 100.
        #expect(position == CGPoint(x: 200, y: 100))
    }

    @Test("Клэмп по X и Y независим друг от друга")
    func axesAreClampedIndependently() {
        // X внутри допустимого диапазона, Y выходит за верхнюю границу.
        let position = CameraMath.clampedPosition(
            target: CGPoint(x: 500, y: 900),
            viewportSize: CGSize(width: 400, height: 200),
            levelSize: CGSize(width: 1000, height: 600)
        )
        #expect(position == CGPoint(x: 500, y: 500))
    }
}
