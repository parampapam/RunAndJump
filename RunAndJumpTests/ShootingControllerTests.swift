//
//  ShootingControllerTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 27.07.2026.
//

import CoreGraphics
import Foundation
import Testing
@testable import RunAndJump

/// Оружие с круглыми числами: видит на 5 тайлов (300 пт), терпит 2 тайла
/// (120 пт) по высоте, целится 0.5 с, перезаряжается 1 с.
private let testWeapon = EnemyWeapon(
    sightRangeInTiles: 5,
    verticalToleranceInTiles: 2,
    aimDelay: 0.5,
    cooldown: 1.0,
    projectileSpeed: 300,
    projectileRangeInTiles: 6
)

private let shooterPosition = CGPoint(x: 500, y: 100)

struct ShootingRulesTests {

    private func canSee(_ target: CGPoint, facing: EnemyFacing = .right) -> Bool {
        ShootingRules.canSee(shooter: shooterPosition,
                             facing: facing,
                             target: target,
                             weapon: testWeapon)
    }

    @Test func seesTargetAheadInRange() {
        #expect(canSee(CGPoint(x: 700, y: 100)))
    }

    /// Цель за спиной не считается: снаряд летит только вперёд.
    @Test func doesNotSeeTargetBehind() {
        #expect(!canSee(CGPoint(x: 300, y: 100)))
        #expect(canSee(CGPoint(x: 300, y: 100), facing: .left))
    }

    /// Ровно на месте стрелка — не «впереди» ни в одну сторону.
    @Test func doesNotSeeTargetAtOwnPosition() {
        #expect(!canSee(shooterPosition))
        #expect(!canSee(shooterPosition, facing: .left))
    }

    @Test func rangeIsInclusive() {
        #expect(canSee(CGPoint(x: 500 + testWeapon.sightRange, y: 100)))
        #expect(!canSee(CGPoint(x: 500 + testWeapon.sightRange + 1, y: 100)))
    }

    /// Снаряд летит горизонтально — по цели заметно выше стрелок не стреляет.
    @Test func ignoresTargetTooHighOrTooLow() {
        #expect(canSee(CGPoint(x: 600, y: 100 + testWeapon.verticalTolerance)))
        #expect(!canSee(CGPoint(x: 600, y: 100 + testWeapon.verticalTolerance + 1)))
        #expect(!canSee(CGPoint(x: 600, y: 100 - testWeapon.verticalTolerance - 1)))
    }
}

struct ShootingControllerTests {

    private let targetInSight = CGPoint(x: 700, y: 100)
    private let targetOutOfSight = CGPoint(x: 5000, y: 100)

    private func fires(_ controller: inout ShootingController,
                       at time: TimeInterval,
                       target: CGPoint) -> Bool {
        controller.update(at: time, shooter: shooterPosition, facing: .right, target: target)
    }

    /// Заметив цель, стрелок сначала целится — мгновенного выстрела в упор нет.
    @Test func doesNotFireBeforeAimDelay() {
        var controller = ShootingController(weapon: testWeapon)
        #expect(!fires(&controller, at: 10.0, target: targetInSight))
        #expect(!fires(&controller, at: 10.4, target: targetInSight))
        #expect(fires(&controller, at: 10.5, target: targetInSight))
    }

    /// Пока цель на виду, выстрелы идут ровно через кулдаун.
    @Test func repeatsShotsAfterCooldown() {
        var controller = ShootingController(weapon: testWeapon)
        #expect(!fires(&controller, at: 0.0, target: targetInSight))  // заметил цель
        #expect(fires(&controller, at: 0.5, target: targetInSight))   // прицелился
        #expect(!fires(&controller, at: 1.4, target: targetInSight))
        #expect(fires(&controller, at: 1.5, target: targetInSight))
        #expect(!fires(&controller, at: 2.0, target: targetInSight))
        #expect(fires(&controller, at: 2.5, target: targetInSight))
    }

    @Test func neverFiresWithoutTargetInSight() {
        var controller = ShootingController(weapon: testWeapon)
        for frame in 0...100 {
            #expect(!fires(&controller, at: TimeInterval(frame) / 60, target: targetOutOfSight))
        }
    }

    /// Потеря цели сбрасывает прицеливание: вернувшийся игрок снова получает фору.
    @Test func losingSightResetsAiming() {
        var controller = ShootingController(weapon: testWeapon)
        #expect(!fires(&controller, at: 0.0, target: targetInSight))
        // Игрок ушёл из зоны в момент, когда до выстрела оставалось чуть-чуть.
        #expect(!fires(&controller, at: 0.4, target: targetOutOfSight))
        // Вернулся — отсчёт прицеливания начинается заново.
        #expect(!fires(&controller, at: 0.5, target: targetInSight))
        #expect(fires(&controller, at: 1.0, target: targetInSight))
    }

    /// Пропуск кадров (просадка fps) не «копит» выстрелы — за кадр не больше одного.
    @Test func firesAtMostOncePerFrame() {
        var controller = ShootingController(weapon: testWeapon)
        #expect(!fires(&controller, at: 0.0, target: targetInSight))
        #expect(fires(&controller, at: 0.5, target: targetInSight))
        // Кадр «пропал» на 9.5 с — это всё равно один выстрел, а не очередь.
        #expect(fires(&controller, at: 10.0, target: targetInSight))
        #expect(!fires(&controller, at: 10.0, target: targetInSight))
    }
}
