//
//  EnemyKindTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 26.07.2026.
//

import CoreGraphics
import Testing
@testable import RunAndJump

struct EnemyKindTests {

    @Test(arguments: [EnemyKind.crab, .imp, .sniper])
    func walkingKindsPatrol(kind: EnemyKind) {
        #expect(kind.movementStyle == .patrolling)
    }

    @Test(arguments: [EnemyKind.plant, .wasp])
    func rootedKindsStayInPlace(kind: EnemyKind) {
        #expect(kind.movementStyle == .stationary)
    }

    @Test(arguments: EnemyKind.allCases)
    func defeatEventCarriesKindPoints(kind: EnemyKind) {
        #expect(kind.defeatEvent == .enemyDefeated(points: kind.defeatPoints))
    }

    @Test(arguments: EnemyKind.allCases)
    func defeatingEnemyAddsItsPointsToBonus(kind: EnemyKind) {
        let state = PlayerState(health: 3, bonusPoints: 10)
        let new = GameRules.apply(kind.defeatEvent, to: state)
        #expect(new.bonusPoints == 10 + kind.defeatPoints)
        #expect(new.health == 3) // победа над врагом здоровье не меняет
    }

    /// Убитый враг не завершает уровень и не убивает игрока.
    @Test func defeatingEnemyKeepsLevelRunning() {
        let state = PlayerState(health: 3, bonusPoints: 0)
        let new = GameRules.apply(EnemyKind.crab.defeatEvent, to: state)
        #expect(GameRules.outcome(after: EnemyKind.crab.defeatEvent, in: new) == .playing)
    }

    /// Шкала наград: до кого труднее дотянуться, тот дороже.
    @Test func defeatPointsGrowWithDifficulty() {
        #expect(EnemyKind.plant.defeatPoints < EnemyKind.crab.defeatPoints)
        #expect(EnemyKind.crab.defeatPoints < EnemyKind.imp.defeatPoints)
        #expect(EnemyKind.imp.defeatPoints < EnemyKind.wasp.defeatPoints)
        #expect(EnemyKind.wasp.defeatPoints < EnemyKind.sniper.defeatPoints)
    }

    @Test func patrollingDescriptorKeepsItsRange() {
        let descriptor = EnemyDescriptor.patrolling(.crab,
                                                    at: TileCoordinate(x: 5, y: 1),
                                                    leftX: 4, rightX: 8, speed: 120)
        #expect(descriptor.behavior == .patrolling(leftX: 4, rightX: 8, speed: 120))
    }

    @Test(arguments: EnemyKind.allCases)
    func stationaryDescriptorNeverMoves(kind: EnemyKind) {
        let descriptor = EnemyDescriptor.stationary(kind, at: TileCoordinate(x: 3, y: 1))
        #expect(descriptor.behavior == .stationary)
    }

    /// Вид врага главнее описания: растению патруль задать нельзя.
    @Test(arguments: [EnemyKind.plant, .wasp])
    func patrolIsIgnoredForStationaryKinds(kind: EnemyKind) {
        let descriptor = EnemyDescriptor(
            origin: TileCoordinate(x: 3, y: 1),
            kind: kind,
            patrol: EnemyDescriptor.Patrol(leftX: 1, rightX: 5, speed: 100)
        )
        #expect(descriptor.behavior == .stationary)
    }
}
