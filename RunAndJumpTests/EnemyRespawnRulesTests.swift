//
//  EnemyRespawnRulesTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 08.08.2026.
//

import CoreGraphics
import Testing
@testable import RunAndJump

struct EnemyRespawnRulesTests {

    private let enemies: [EnemyDescriptor] = [
        .stationary(.plant, at: TileCoordinate(x: 10, y: 1)),   // 10 очков
        .patrolling(.crab, at: TileCoordinate(x: 15, y: 1),
                    leftX: 14, rightX: 18, speed: 100),         // 15 очков
        .patrolling(.imp, at: TileCoordinate(x: 28, y: 1),
                    leftX: 26, rightX: 30, speed: 120),         // 20 очков
    ]

    @Test func nothingRestoredCostsNothing() {
        #expect(EnemyRespawnRules.refund(for: [], in: enemies) == 0)
    }

    @Test func refundIsTheEnemyOwnPoints() {
        #expect(EnemyRespawnRules.refund(for: [0], in: enemies) == EnemyKind.plant.defeatPoints)
        #expect(EnemyRespawnRules.refund(for: [2], in: enemies) == EnemyKind.imp.defeatPoints)
    }

    @Test func refundSumsEveryRestoredEnemy() {
        let expected = EnemyKind.plant.defeatPoints + EnemyKind.imp.defeatPoints
        #expect(EnemyRespawnRules.refund(for: [0, 2], in: enemies) == expected)
    }

    /// Описание уровня могло измениться — неизвестный индекс не должен ронять игру.
    @Test func unknownIndexIsIgnored() {
        #expect(EnemyRespawnRules.refund(for: [7], in: enemies) == 0)
        #expect(EnemyRespawnRules.refund(for: [1, 7], in: enemies) == EnemyKind.crab.defeatPoints)
    }
}
