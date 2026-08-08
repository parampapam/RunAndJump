//
//  HealthRulesTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 08.08.2026.
//

import Testing
@testable import RunAndJump

struct HealthRulesTests {

    /// Своя конфигурация — проверяем, что правила читают числа из неё,
    /// а не из зашитых в код констант.
    private let custom = HealthConfiguration(
        initial: 50,
        maximum: 80,
        enemyHitDamage: 15,
        pickupHeal: 5,
        warningFraction: 0.5,
        criticalFraction: 0.25
    )

    @Test("Стандартная конфигурация — та, о которой договорились")
    func standardValues() {
        let c = HealthConfiguration.standard
        #expect(c.initial == 100)
        #expect(c.maximum == 200)
        #expect(c.enemyHitDamage == 20)
        #expect(c.pickupHeal == 10)
        #expect(c.initial <= c.maximum)
    }

    @Test("Здоровье не уходит ниже нуля и не поднимается выше потолка")
    func clampKeepsHealthInRange() {
        #expect(HealthRules.clamp(-30) == 0)
        #expect(HealthRules.clamp(0) == 0)
        #expect(HealthRules.clamp(120) == 120)
        #expect(HealthRules.clamp(500) == HealthConfiguration.standard.maximum)
        #expect(HealthRules.clamp(500, configuration: custom) == custom.maximum)
    }

    @Test("Полная шкала — это потолок: старт заполняет её наполовину")
    func fillFractionIsRelativeToMaximum() {
        let c = HealthConfiguration.standard
        #expect(HealthRules.fillFraction(for: c.initial) == 0.5)
        #expect(HealthRules.fillFraction(for: c.maximum) == 1.0)
        #expect(HealthRules.fillFraction(for: 0) == 0.0)
        #expect(HealthRules.fillFraction(for: -50) == 0.0)
        #expect(HealthRules.fillFraction(for: c.maximum * 2) == 1.0)
    }

    @Test(arguments: [
        (200, HealthLevel.healthy),
        (100, HealthLevel.healthy), // старт уровня — зелёный
        (51, HealthLevel.healthy),
        (50, HealthLevel.warning),
        (30, HealthLevel.warning),
        (20, HealthLevel.critical), // осталось одно касание врага
        (0, HealthLevel.critical),
    ])
    func levelFollowsFraction(health: Int, expected: HealthLevel) {
        #expect(HealthRules.level(for: health) == expected)
    }

    @Test("Пороги идут по возрастанию и не выходят за шкалу")
    func thresholdsAreOrdered() {
        let c = HealthConfiguration.standard
        #expect(c.criticalFraction < c.warningFraction)
        #expect(c.warningFraction < 1)
        #expect(HealthRules.level(for: c.initial) == .healthy)
    }

    @Test("Урон и лечение берутся из конфигурации")
    func rulesReadNumbersFromConfiguration() {
        let state = PlayerState(health: 50, bonusPoints: 0)

        #expect(GameRules.apply(.enemyHit, to: state, health: custom).health == 35)
        #expect(GameRules.apply(.healthPickup, to: state, health: custom).health == 55)
    }

    @Test("Аптечка сверх потолка пропадает")
    func healthPickupCannotExceedMaximum() {
        let c = HealthConfiguration.standard
        let state = PlayerState(health: c.maximum - 1, bonusPoints: 0)
        let new = GameRules.apply(.healthPickup, to: state)
        #expect(new.health == c.maximum)
    }

    @Test("Смертельный удар обнуляет шкалу, а не уводит её в минус")
    func fatalHitClampsToZero() {
        let state = PlayerState(health: 5, bonusPoints: 0)
        let new = GameRules.apply(.enemyHit, to: state)
        #expect(new.health == 0)
        #expect(GameRules.isDead(new))
    }

    @Test("Новый уровень начинается со стартового запаса из конфигурации")
    func levelStartsWithConfiguredHealth() {
        let progress = GameProgress(currentLevelIndex: 2, carriedBonusPoints: 40)
        let state = GameProgressRules.initialPlayerState(for: progress, health: custom)
        #expect(state.health == custom.initial)
        #expect(state.bonusPoints == 40)
    }
}
