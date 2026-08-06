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
        #expect(PlatformTiling.textureNames(forWidthInTiles: 1) == [TextureName.Platform.middle])
    }

    @Test("Платформа в два тайла — только левый и правый торец")
    func twoTilesAreCapsOnly() {
        #expect(PlatformTiling.textureNames(forWidthInTiles: 2) == [
            TextureName.Platform.left,
            TextureName.Platform.right,
        ])
    }

    @Test("Платформа в три тайла — торцы и одна середина")
    func threeTilesHaveOneMiddle() {
        #expect(PlatformTiling.textureNames(forWidthInTiles: 3) == [
            TextureName.Platform.left,
            TextureName.Platform.middle,
            TextureName.Platform.right,
        ])
    }

    @Test("Середина повторяется по ширине")
    func middleRepeats() {
        let names = PlatformTiling.textureNames(forWidthInTiles: 6)
        #expect(names.count == 6)
        #expect(names.first == TextureName.Platform.left)
        #expect(names.last == TextureName.Platform.right)
        #expect(names.dropFirst().dropLast().allSatisfy { $0 == TextureName.Platform.middle })
    }

    @Test("Дробная ширина округляется до ближайшего числа колонок")
    func fractionalWidthRoundsToNearestColumnCount() {
        #expect(PlatformTiling.columnCount(forWidthInTiles: 2.4) == 2)
        #expect(PlatformTiling.columnCount(forWidthInTiles: 2.6) == 3)
    }

    @Test("Ширина меньше тайла всё равно даёт одну колонку")
    func narrowPlatformStillHasOneColumn() {
        #expect(PlatformTiling.columnCount(forWidthInTiles: 0.3) == 1)
        #expect(PlatformTiling.textureNames(forWidthInTiles: 0.3) == [TextureName.Platform.middle])
    }
}
