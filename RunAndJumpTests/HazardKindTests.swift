//
//  HazardKindTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 30.07.2026.
//

import Testing
@testable import RunAndJump

struct HazardKindTests {

    @Test("Каждая опасная зона наносит урон и порождает событие с ним же")
    func eventCarriesDamage() {
        for kind in HazardKind.allCases {
            #expect(kind.damage > 0)
            #expect(kind.event == .hazardHit(damage: kind.damage))
        }
    }

    @Test("Пауза между ударами положительна — иначе зона снимала бы жизнь каждый кадр")
    func damageIntervalIsPositive() {
        for kind in HazardKind.allCases {
            #expect(kind.damageInterval > 0)
        }
    }

    @Test("Лава опаснее воды: бьёт больнее и чаще")
    func lavaIsHarsherThanWater() {
        #expect(HazardKind.lava.damage > HazardKind.water.damage)
        #expect(HazardKind.lava.damageInterval < HazardKind.water.damageInterval)
    }

    @Test("Урон зоны соразмерен шкале здоровья: не больше половины запаса за удар")
    func damageFitsHealthScale() {
        let configuration = HealthConfiguration.standard
        for kind in HazardKind.allCases {
            #expect(kind.damage <= configuration.initial / 2)
        }
    }

    @Test("Попадание в зону снимает здоровье по номиналу события")
    func hazardHitReducesHealth() {
        let state = PlayerState(health: 100, bonusPoints: 0)

        let afterWater = GameRules.apply(HazardKind.water.event, to: state)
        #expect(afterWater.health == 100 - HazardKind.water.damage)

        let afterLava = GameRules.apply(HazardKind.lava.event, to: state)
        #expect(afterLava.health == 100 - HazardKind.lava.damage)
    }

    @Test("Попадание в зону не трогает набранные очки")
    func hazardHitKeepsBonusPoints() {
        let state = PlayerState(health: 100, bonusPoints: 25)
        let after = GameRules.apply(.hazardHit(damage: 20), to: state)
        #expect(after.bonusPoints == 25)
    }

    @Test("Если здоровья не хватило — уровень проигран")
    func fatalHazardHitEndsLevel() {
        let state = PlayerState(health: 10, bonusPoints: 0)
        let event = GameEvent.hazardHit(damage: 20)
        let after = GameRules.apply(event, to: state)

        #expect(GameRules.isDead(after))
        #expect(GameRules.outcome(after: event, in: after) == .died)
    }

    @Test("Пережитое попадание оставляет уровень в игре")
    func survivedHazardHitKeepsPlaying() {
        let state = PlayerState(health: 100, bonusPoints: 0)
        let event = GameEvent.hazardHit(damage: 20)
        let after = GameRules.apply(event, to: state)

        #expect(!GameRules.isDead(after))
        #expect(GameRules.outcome(after: event, in: after) == .playing)
    }
}
