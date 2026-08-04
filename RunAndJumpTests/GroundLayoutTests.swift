//
//  GroundLayoutTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 03.08.2026.
//

import Testing
import CoreGraphics
@testable import RunAndJump

struct GroundLayoutTests {

    @Test("Без озёр земля сплошная")
    func noGapsIsSolidGround() {
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: []) == [0...45])
    }

    @Test("Озеро посередине разрезает землю надвое")
    func gapSplitsGround() {
        let segments = GroundLayout.segments(levelWidthInTiles: 45, gaps: [23...25])
        #expect(segments == [0...23, 25...45])
    }

    @Test("Каждое озеро добавляет проём")
    func severalGapsSplitFurther() {
        let segments = GroundLayout.segments(levelWidthInTiles: 45, gaps: [6...8, 20...22])
        #expect(segments == [0...6, 8...20, 22...45])
    }

    @Test("Порядок озёр в описании уровня не важен")
    func orderOfGapsDoesNotMatter() {
        let sorted = GroundLayout.segments(levelWidthInTiles: 45, gaps: [6...8, 20...22])
        let shuffled = GroundLayout.segments(levelWidthInTiles: 45, gaps: [20...22, 6...8])
        #expect(sorted == shuffled)
    }

    @Test("Озеро у самого края не оставляет куска перед собой")
    func gapAtLevelStart() {
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: [0...2]) == [2...45])
    }

    @Test("Озеро в конце уровня обрезает последний кусок")
    func gapAtLevelEnd() {
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: [43...45]) == [0...43])
    }

    @Test("Соприкасающиеся озёра дают один проём, а не кусок нулевой ширины")
    func touchingGapsMerge() {
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: [10...12, 12...14]) == [0...10, 14...45])
    }

    @Test("Пересекающиеся озёра схлопываются в один проём")
    func overlappingGapsMerge() {
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: [10...14, 12...16]) == [0...10, 16...45])
    }

    @Test("Вложенное озеро не режет землю второй раз")
    func nestedGapIsAbsorbed() {
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: [10...20, 12...14]) == [0...10, 20...45])
    }

    @Test("Проём во всю ширину не оставляет земли")
    func gapOverWholeLevelLeavesNothing() {
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: [0...45]).isEmpty)
    }

    @Test("Вылезающий за уровень проём обрезается по его границам")
    func gapBeyondLevelIsClamped() {
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: [-5...2]) == [2...45])
        #expect(GroundLayout.segments(levelWidthInTiles: 45, gaps: [43...50]) == [0...43])
    }

    @Test("Куски покрывают всю землю, кроме проёмов")
    func segmentsCoverEverythingButGaps() {
        let gaps: [ClosedRange<CGFloat>] = [6...8, 20...22]
        let segments = GroundLayout.segments(levelWidthInTiles: 45, gaps: gaps)
        let covered = segments.reduce(CGFloat(0)) { $0 + ($1.upperBound - $1.lowerBound) }
        let cut = gaps.reduce(CGFloat(0)) { $0 + ($1.upperBound - $1.lowerBound) }
        #expect(covered == 45 - cut)
    }
}
