//
//  CheckpointRulesTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 08.08.2026.
//

import CoreGraphics
import Testing
@testable import RunAndJump

struct CheckpointRulesTests {

    private let levelStart = TileCoordinate(x: 1, y: 1)
    private let checkpoints = [
        CheckpointDescriptor(origin: TileCoordinate(x: 8, y: 1)),
        CheckpointDescriptor(origin: TileCoordinate(x: 19, y: 1)),
        CheckpointDescriptor(origin: TileCoordinate(x: 31, y: 1)),
    ]

    // MARK: - Точка возрождения

    @Test func respawnsAtLevelStartUntilAnyFlagPassed() {
        let origin = CheckpointRules.respawnOrigin(checkpoints: checkpoints,
                                                   levelStart: levelStart,
                                                   activated: nil)
        #expect(origin == levelStart)
    }

    @Test func respawnsAtActiveCheckpoint() {
        let origin = CheckpointRules.respawnOrigin(checkpoints: checkpoints,
                                                   levelStart: levelStart,
                                                   activated: 1)
        #expect(origin == TileCoordinate(x: 19, y: 1))
    }

    @Test func respawnsAtLevelStartOnLevelWithoutCheckpoints() {
        let origin = CheckpointRules.respawnOrigin(checkpoints: [],
                                                   levelStart: levelStart,
                                                   activated: nil)
        #expect(origin == levelStart)
    }

    @Test func unknownIndexFallsBackToLevelStart() {
        let origin = CheckpointRules.respawnOrigin(checkpoints: checkpoints,
                                                   levelStart: levelStart,
                                                   activated: 7)
        #expect(origin == levelStart)
    }

    // MARK: - Проход мимо флага

    @Test func firstPassedFlagBecomesActive() {
        #expect(CheckpointRules.activation(touched: 0, active: nil) == .activate)
    }

    @Test func laterFlagReplacesActiveOne() {
        #expect(CheckpointRules.activation(touched: 2, active: 0) == .activate)
    }

    /// Возвращение назад тоже переносит точку: текущая — та, мимо которой
    /// прошли последней, а не самая дальняя.
    @Test func earlierFlagAlsoBecomesActive() {
        #expect(CheckpointRules.activation(touched: 0, active: 2) == .activate)
    }

    @Test func passingActiveFlagAgainChangesNothing() {
        #expect(CheckpointRules.activation(touched: 1, active: 1) == .ignore)
    }

    // MARK: - Состояние флагов

    @Test func onlyActiveFlagIsRaised() {
        #expect(CheckpointRules.state(of: 1, active: 1) == .raised)
        #expect(CheckpointRules.state(of: 0, active: 1) == .lowered)
        #expect(CheckpointRules.state(of: 2, active: 1) == .lowered)
    }

    @Test func allFlagsLoweredBeforeFirstPass() {
        for index in checkpoints.indices {
            #expect(CheckpointRules.state(of: index, active: nil) == .lowered)
        }
    }
}
