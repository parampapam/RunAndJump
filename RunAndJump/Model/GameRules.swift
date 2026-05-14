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
    case healthPickup
    case bonusPickup(points: Int)
    case reachedPortal
}

enum GameRules {
    /// Применяет событие к состоянию и возвращает новое состояние.
    /// Чистая функция: одинаковый вход → одинаковый выход, никаких побочных эффектов.
    static func apply(_ event: GameEvent, to state: PlayerState) -> PlayerState {
        var new = state
        switch event {
        case .enemyHit:
            new.health -= 1
        case .healthPickup:
            new.health += 1
        case .bonusPickup(let points):
            new.bonusPoints += points
        case .reachedPortal:
            // Сам факт достижения портала состояние не меняет;
            // переход между сценами будет обрабатываться отдельно.
            break
        }
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
