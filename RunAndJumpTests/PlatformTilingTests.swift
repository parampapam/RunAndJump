//
//  PlatformTilingTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
@testable import RunAndJump

@Suite("PlatformTiling — раскладка платформы по колонкам")
struct PlatformTilingTests {

    @Test("Платформа шириной в тайл — одна средняя плитка, без торцов")
    func singleTileHasNoCaps() {
        #expect(PlatformTiling.parts(forWidthInTiles: 1) == [.middle])
    }

    @Test("Платформа в два тайла — только левый и правый торец")
    func twoTilesAreCapsOnly() {
        #expect(PlatformTiling.parts(forWidthInTiles: 2) == [
            .left,
            .right,
        ])
    }

    @Test("Платформа в три тайла — торцы и одна середина")
    func threeTilesHaveOneMiddle() {
        #expect(PlatformTiling.parts(forWidthInTiles: 3) == [
            .left,
            .middle,
            .right,
        ])
    }

    @Test("Середина повторяется по ширине")
    func middleRepeats() {
        let parts = PlatformTiling.parts(forWidthInTiles: 6)
        #expect(parts.count == 6)
        #expect(parts.first == .left)
        #expect(parts.last == .right)
        #expect(parts.dropFirst().dropLast().allSatisfy { $0 == .middle })
    }

    @Test("Дробная ширина округляется до ближайшего числа колонок")
    func fractionalWidthRoundsToNearestColumnCount() {
        #expect(PlatformTiling.columnCount(forWidthInTiles: 2.4) == 2)
        #expect(PlatformTiling.columnCount(forWidthInTiles: 2.6) == 3)
    }

    @Test("Ширина меньше тайла всё равно даёт одну колонку")
    func narrowPlatformStillHasOneColumn() {
        #expect(PlatformTiling.columnCount(forWidthInTiles: 0.3) == 1)
        #expect(PlatformTiling.parts(forWidthInTiles: 0.3) == [.middle])
    }
}
