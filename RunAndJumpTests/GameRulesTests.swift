//
//  GameRulesTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 05.05.2026.
//

import Testing
@testable import RunAndJump

struct GameRulesTests {

    @Test func enemyHitReducesHealthByOne() {
        let state = PlayerState(health: 5, bonusPoints: 10)
        let new = GameRules.apply(.enemyHit, to: state)
        #expect(new.health == 4)
        #expect(new.bonusPoints == 10) // бонус не меняется
    }

    @Test func healthPickupIncreasesHealth() {
        let state = PlayerState(health: 3, bonusPoints: 0)
        let new = GameRules.apply(.healthPickup, to: state)
        #expect(new.health == 4)
    }

    @Test func bonusPickupAddsPoints() {
        let state = PlayerState(health: 5, bonusPoints: 10)
        let new = GameRules.apply(.bonusPickup(points: 5), to: state)
        #expect(new.bonusPoints == 15)
        #expect(new.health == 5) // здоровье не меняется
    }

    @Test func reachedPortalDoesNotChangeState() {
        let state = PlayerState(health: 3, bonusPoints: 7)
        let new = GameRules.apply(.reachedPortal, to: state)
        #expect(new == state)
    }

    @Test func deathDetection() {
        #expect(GameRules.isDead(PlayerState(health: 0, bonusPoints: 5)) == true)
        #expect(GameRules.isDead(PlayerState(health: 1, bonusPoints: 0)) == false)
        #expect(GameRules.isDead(PlayerState(health: -1, bonusPoints: 0)) == true)
    }

    @Test(arguments: [
        (5, GameEvent.enemyHit, 4),
        (1, GameEvent.enemyHit, 0),
        (3, GameEvent.healthPickup, 4),
    ])
    func healthChangesParametrized(initialHealth: Int, event: GameEvent, expectedHealth: Int) {
        let state = PlayerState(health: initialHealth, bonusPoints: 0)
        let new = GameRules.apply(event, to: state)
        #expect(new.health == expectedHealth)
    }

    @Test func outcomePlayingAfterRegularEvent() {
        let state = PlayerState(health: 4, bonusPoints: 0)
        let outcome = GameRules.outcome(after: .enemyHit, in: state)
        #expect(outcome == .playing)
    }

    @Test func outcomeDiedWhenHealthZero() {
        let state = PlayerState(health: 0, bonusPoints: 0)
        let outcome = GameRules.outcome(after: .enemyHit, in: state)
        #expect(outcome == .died)
    }

    @Test func outcomeCompletedAtPortal() {
        let state = PlayerState(health: 3, bonusPoints: 10)
        let outcome = GameRules.outcome(after: .reachedPortal, in: state)
        #expect(outcome == .completed)
    }

    @Test func portalCompletesEvenWithLowHealth() {
        let state = PlayerState(health: 1, bonusPoints: 0)
        let outcome = GameRules.outcome(after: .reachedPortal, in: state)
        #expect(outcome == .completed)
    }
}
