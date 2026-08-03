//
//  HazardImmersionTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 03.08.2026.
//

import Testing
import CoreGraphics
@testable import RunAndJump

struct HazardImmersionTests {

    /// Игрок шириной в тайл (60) и озеро в два тайла — как на уровнях.
    private let lake: ClosedRange<CGFloat> = 100...220

    private func player(centeredAt x: CGFloat, width: CGFloat = 60) -> ClosedRange<CGFloat> {
        (x - width / 2)...(x + width / 2)
    }

    @Test("Целиком в озере — полное погружение")
    func fullyInsideIsFullDepth() {
        #expect(HazardImmersion.depth(player: player(centeredAt: 160), hazard: lake) == 1)
    }

    @Test("Вне озера — погружения нет")
    func outsideIsZero() {
        #expect(HazardImmersion.depth(player: player(centeredAt: 40), hazard: lake) == 0)
        #expect(HazardImmersion.depth(player: player(centeredAt: 300), hazard: lake) == 0)
    }

    @Test("Касание кромки ещё не топит")
    func touchingEdgeIsZero() {
        // Правый бок игрока ровно на левой кромке озера.
        #expect(HazardImmersion.depth(player: player(centeredAt: 70), hazard: lake) == 0)
    }

    @Test("На кромке погружение равно зашедшей доле")
    func partialOverlapIsPartialDepth() {
        // Половина ширины игрока над озером.
        #expect(HazardImmersion.depth(player: player(centeredAt: 100), hazard: lake) == 0.5)
        // Четверть — на выходе из озера.
        #expect(HazardImmersion.depth(player: player(centeredAt: 205), hazard: lake) == 0.75)
    }

    @Test("Погружение растёт монотонно, пока игрок входит в озеро")
    func depthGrowsWhileEntering() {
        var previous: CGFloat = -1
        for x in stride(from: CGFloat(70), through: 130, by: 5) {
            let depth = HazardImmersion.depth(player: player(centeredAt: x), hazard: lake)
            #expect(depth >= previous)
            previous = depth
        }
        #expect(previous == 1)
    }

    @Test("Озеро уже игрока всё равно топит целиком")
    func narrowHazardStillDrowns() {
        let puddle: ClosedRange<CGFloat> = 100...130
        #expect(HazardImmersion.depth(player: player(centeredAt: 115), hazard: puddle) == 1)
    }

    @Test("Вырожденная зона нулевой ширины ничего не делает")
    func zeroWidthHazardIsZero() {
        #expect(HazardImmersion.depth(player: player(centeredAt: 100), hazard: 100...100) == 0)
    }
}
