//
//  ProjectileRulesTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 27.07.2026.
//

import CoreGraphics
import Testing
@testable import RunAndJump

struct ProjectileRulesTests {

    private let weapon = EnemyWeapon(
        sightRangeInTiles: 5,
        verticalToleranceInTiles: 2,
        aimDelay: 0.5,
        cooldown: 1.0,
        projectileSpeed: 300,
        projectileRangeInTiles: 6
    )

    /// Враг 0.75 тайла шириной (45 пт) с центром в (500, 100).
    private let shooterCenter = CGPoint(x: 500, y: 100)
    private let shooterSize = CGSize(width: 45, height: 45)

    private func spawn(facing: EnemyFacing) -> ProjectileSpawn {
        ProjectileRules.spawn(shooterCenter: shooterCenter,
                              shooterSize: shooterSize,
                              facing: facing,
                              weapon: weapon)
    }

    /// Снаряд рождается у переднего края врага, а не внутри него.
    @Test func spawnsAtMuzzleFacingRight() {
        let result = spawn(facing: .right)
        #expect(result.position.x == 500 + 22.5 + ProjectileRules.muzzleGap)
        #expect(result.position.y == 100)
        #expect(result.velocity.dx == 300)
        #expect(result.velocity.dy == 0)
    }

    @Test func spawnsAtMuzzleFacingLeft() {
        let result = spawn(facing: .left)
        #expect(result.position.x == 500 - 22.5 - ProjectileRules.muzzleGap)
        #expect(result.position.y == 100)
        #expect(result.velocity.dx == -300)
    }

    /// Ресурс полёта = дальность / скорость: 6 тайлов (360 пт) при 300 пт/с.
    @Test func lifetimeCoversDeclaredRange() {
        #expect(spawn(facing: .right).lifetime == 1.2)
    }

    @Test func zeroSpeedDoesNotProduceInfiniteLifetime() {
        let stalled = EnemyWeapon(sightRangeInTiles: 5,
                                  verticalToleranceInTiles: 2,
                                  aimDelay: 0,
                                  cooldown: 1,
                                  projectileSpeed: 0,
                                  projectileRangeInTiles: 6)
        #expect(stalled.projectileLifetime == 0)
    }
}
