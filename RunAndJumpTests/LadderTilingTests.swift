//
//  LadderTilingTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
@testable import RunAndJump

@Suite("LadderTiling — раскладка лестницы по тайлам")
struct LadderTilingTests {

    @Test("Высота не больше тайла даёт одну нижнюю плитку высотой в тайл")
    func shortLadderIsSingleBottomTile() {
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 0.3)
        #expect(tiles == [.init(heightInTiles: 1, part: .bottom)])
        #expect(total == 1)
    }

    @Test("Высота ровно в тайл — тоже одна нижняя плитка")
    func exactlyOneTileIsSingleBottomTile() {
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 1)
        #expect(tiles == [.init(heightInTiles: 1, part: .bottom)])
        #expect(total == 1)
    }

    @Test("Целая высота в 2 тайла — низ и верх (100%), без середины")
    func twoWholeTilesHasNoMiddle() {
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 2)
        #expect(tiles == [
            .init(heightInTiles: 1, part: .bottom),
            .init(heightInTiles: 1, part: .top(fraction: 1)),
        ])
        #expect(total == 2)
    }

    @Test("Высота кратна тайлу (5) — низ, середины, верх (100%), без округления")
    func wholeTilesFillMiddleWithFullTopTexture() {
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 5)
        #expect(tiles == [
            .init(heightInTiles: 1, part: .bottom),
            .init(heightInTiles: 1, part: .middle),
            .init(heightInTiles: 1, part: .middle),
            .init(heightInTiles: 1, part: .middle),
            .init(heightInTiles: 1, part: .top(fraction: 1)),
        ])
        #expect(total == 5)
    }

    @Test("Остаток ровно 25% — верхняя плитка 25%, итоговая высота не округляется")
    func quarterRemainderMatchesExactly() {
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 2.25)
        #expect(tiles.last == .init(heightInTiles: 0.25, part: .top(fraction: 0.25)))
        #expect(total == 2.25)
    }

    @Test("Остаток ровно 50% — верхняя плитка 50%, итоговая высота не округляется")
    func halfRemainderMatchesExactly() {
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 3.5)
        #expect(tiles.last == .init(heightInTiles: 0.5, part: .top(fraction: 0.5)))
        #expect(total == 3.5)
    }

    @Test("Остаток ровно 75% — верхняя плитка 75%, итоговая высота не округляется")
    func threeQuarterRemainderMatchesExactly() {
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 4.75)
        #expect(tiles.last == .init(heightInTiles: 0.75, part: .top(fraction: 0.75)))
        #expect(total == 4.75)
    }

    @Test("Остаток между вариантами текстур округляется вверх до ближайшего")
    func inBetweenRemainderRoundsUp() {
        // 0.3 > 25%, попадает в бакет 50% — итоговая высота растёт до 2.5.
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 2.3)
        #expect(tiles.last == .init(heightInTiles: 0.5, part: .top(fraction: 0.5)))
        #expect(total == 2.5)
    }

    @Test("Остаток выше 75% округляется до полного тайла — высота лестницы увеличивается на целый тайл")
    func remainderAboveThreeQuartersRoundsUpToWholeTile() {
        let (tiles, total) = LadderTiling.layout(forRequestedHeightInTiles: 2.9)
        #expect(tiles.last == .init(heightInTiles: 1, part: .top(fraction: 1)))
        #expect(total == 3)
    }

    @Test("Итоговая высота никогда не меньше запрошенной — лестница всегда достаёт до опоры")
    func totalHeightNeverShorterThanRequested() {
        for height: CGFloat in [0.1, 0.9, 1, 1.5, 2.01, 2.49, 2.51, 2.99, 6.999] {
            let (_, total) = LadderTiling.layout(forRequestedHeightInTiles: height)
            #expect(total >= height, "высота \(height) дала итог \(total)")
        }
    }
}
