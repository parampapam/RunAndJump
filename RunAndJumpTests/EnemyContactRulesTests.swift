//
//  EnemyContactRulesTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 26.07.2026.
//

import CoreGraphics
import Testing
@testable import RunAndJump

struct EnemyContactRulesTests {

    /// Враг ростом 45 (0.75 тайла) стоит на земле: низ 60, макушка 105,
    /// порог прыжка сверху — 82.5.
    private let enemyTop: CGFloat = 105
    private let enemyHeight: CGFloat = 45

    private func outcome(playerBottom: CGFloat, velocityY: CGFloat) -> EnemyContactOutcome {
        EnemyContactRules.outcome(playerBottom: playerBottom,
                                  playerVelocityY: velocityY,
                                  enemyTop: enemyTop,
                                  enemyHeight: enemyHeight)
    }

    @Test func fallingOnHeadIsStomp() {
        #expect(outcome(playerBottom: 100, velocityY: -300) == .stomp)
    }

    /// Игрок бежит по земле — подошва на уровне ног врага, а не макушки.
    @Test func walkingIntoEnemyIsDamage() {
        #expect(outcome(playerBottom: 60, velocityY: 0) == .damage)
    }

    /// Взлетающий игрок бьётся снизу, даже если подошва уже выше порога.
    @Test func hittingFromBelowIsDamage() {
        #expect(outcome(playerBottom: 90, velocityY: 400) == .damage)
    }

    /// В верхней точке прыжка скорость проходит через ноль — касание макушки
    /// там честнее засчитать как прыжок сверху.
    @Test func touchingHeadAtApexIsStomp() {
        #expect(outcome(playerBottom: 104, velocityY: 0) == .stomp)
    }

    @Test func thresholdIsInclusive() {
        let threshold = enemyTop - enemyHeight * EnemyContactRules.stompZone
        #expect(outcome(playerBottom: threshold, velocityY: -100) == .stomp)
        #expect(outcome(playerBottom: threshold - 0.1, velocityY: -100) == .damage)
    }

    /// Падение мимо врага (подошва уже ниже зоны) — это столкновение сбоку.
    @Test func fallingPastTheSideIsDamage() {
        #expect(outcome(playerBottom: 70, velocityY: -300) == .damage)
    }

    /// Летающего врага (оса на y = 2.5) правило считает так же — по его геометрии.
    @Test func flyingEnemyUsesItsOwnGeometry() {
        let waspTop: CGFloat = 195   // низ 150, высота 45
        let result = EnemyContactRules.outcome(playerBottom: 190,
                                               playerVelocityY: -50,
                                               enemyTop: waspTop,
                                               enemyHeight: enemyHeight)
        #expect(result == .stomp)
    }
}
