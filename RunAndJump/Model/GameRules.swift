//
//  GameRules.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 14.05.2026.
//

import Foundation

/// Состояние уровня
enum LevelOutcome: Equatable {
    case playing
    case died
    case completed
}

/// Игровое событие
enum GameEvent: Equatable {
    case enemyHit
    /// Игрок попал в опасную зону (озеро воды или лавы). Величина урона
    /// зависит от вида зоны (`HazardKind.damage`) — событие несёт её с собой,
    /// чтобы правила не знали про виды препятствий.
    case hazardHit(damage: Int)
    case healthPickup
    case bonusPickup(points: Int)
    /// Игрок прыгнул врагу на голову. Очки зависят от вида врага
    /// (`EnemyKind.defeatPoints`) — событие несёт уже посчитанный номинал,
    /// чтобы правила не знали про виды врагов.
    case enemyDefeated(points: Int)
    case reachedPortal
}

enum GameRules {
    /// Применяет событие к состоянию и возвращает новое состояние.
    /// Чистая функция: одинаковый вход → одинаковый выход, никаких побочных эффектов.
    ///
    /// Числа урона и лечения приходят из `HealthConfiguration` — правила знают
    /// только «отнять урон врага», а сколько это в очках, решает конфигурация.
    static func apply(
        _ event: GameEvent,
        to state: PlayerState,
        health configuration: HealthConfiguration = .standard
    ) -> PlayerState {
        var new = state
        switch event {
        case .enemyHit:
            new.health -= configuration.enemyHitDamage
        case .hazardHit(let damage):
            new.health -= damage
        case .healthPickup:
            new.health += configuration.pickupHeal
        case .bonusPickup(let points), .enemyDefeated(let points):
            new.bonusPoints += points
        case .reachedPortal:
            // Сам факт достижения портала состояние не меняет;
            // переход между сценами будет обрабатываться отдельно.
            break
        }
        // Держим здоровье в диапазоне 0...maximum: аптечки сверх потолка
        // пропадают, а смертельный удар не уводит шкалу в минус.
        new.health = HealthRules.clamp(new.health, configuration: configuration)
        return new
    }

    /// Функция по событию и состоянию (после применения события) возвращает новое состояние уровня
    static func outcome(after event: GameEvent, in state: PlayerState) -> LevelOutcome {
            if event == .reachedPortal {
                return .completed
            }
            if state.health <= 0 {
                return .died
            }
            return .playing
        }

    /// Считает игрока погибшим.
    static func isDead(_ state: PlayerState) -> Bool {
        state.health <= 0
    }
}
