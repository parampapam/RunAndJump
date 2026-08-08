//
//  GameRulesTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 05.05.2026.
//

import Testing
@testable import RunAndJump

struct GameRulesTests {

    @Test func enemyHitReducesHealthByConfiguredDamage() {
        let state = PlayerState(health: 100, bonusPoints: 10)
        let new = GameRules.apply(.enemyHit, to: state)
        #expect(new.health == 100 - HealthConfiguration.standard.enemyHitDamage)
        #expect(new.bonusPoints == 10) // бонус не меняется
    }

    @Test func healthPickupIncreasesHealth() {
        let state = PlayerState(health: 60, bonusPoints: 0)
        let new = GameRules.apply(.healthPickup, to: state)
        #expect(new.health == 60 + HealthConfiguration.standard.pickupHeal)
    }

    @Test func bonusPickupAddsPoints() {
        let state = PlayerState(health: 100, bonusPoints: 10)
        let new = GameRules.apply(.bonusPickup(points: 5), to: state)
        #expect(new.bonusPoints == 15)
        #expect(new.health == 100) // здоровье не меняется
    }

    @Test func reachedPortalDoesNotChangeState() {
        let state = PlayerState(health: 60, bonusPoints: 7)
        let new = GameRules.apply(.reachedPortal, to: state)
        #expect(new == state)
    }

    @Test func deathDetection() {
        #expect(GameRules.isDead(PlayerState(health: 0, bonusPoints: 5)) == true)
        #expect(GameRules.isDead(PlayerState(health: 1, bonusPoints: 0)) == false)
        #expect(GameRules.isDead(PlayerState(health: -1, bonusPoints: 0)) == true)
    }

    @Test(arguments: [
        (100, GameEvent.enemyHit, 80),
        (20, GameEvent.enemyHit, 0),
        (10, GameEvent.enemyHit, 0), // ниже нуля шкала не уходит
        (60, GameEvent.healthPickup, 70),
        (200, GameEvent.healthPickup, 200), // выше потолка — тоже
    ])
    func healthChangesParametrized(initialHealth: Int, event: GameEvent, expectedHealth: Int) {
        let state = PlayerState(health: initialHealth, bonusPoints: 0)
        let new = GameRules.apply(event, to: state)
        #expect(new.health == expectedHealth)
    }

    @Test func outcomePlayingAfterRegularEvent() {
        let state = PlayerState(health: 80, bonusPoints: 0)
        let outcome = GameRules.outcome(after: .enemyHit, in: state)
        #expect(outcome == .playing)
    }

    @Test func outcomeDiedWhenHealthZero() {
        let state = PlayerState(health: 0, bonusPoints: 0)
        let outcome = GameRules.outcome(after: .enemyHit, in: state)
        #expect(outcome == .died)
    }

    @Test func outcomeCompletedAtPortal() {
        let state = PlayerState(health: 60, bonusPoints: 10)
        let outcome = GameRules.outcome(after: .reachedPortal, in: state)
        #expect(outcome == .completed)
    }

    @Test func portalCompletesEvenWithLowHealth() {
        let state = PlayerState(health: 10, bonusPoints: 0)
        let outcome = GameRules.outcome(after: .reachedPortal, in: state)
        #expect(outcome == .completed)
    }
}
