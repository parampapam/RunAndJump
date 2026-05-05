//
//  PlayerState.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 05.05.2026.
//

import Foundation

struct PlayerState: Equatable {
    var health: Int
    var bonusPoints: Int

    static let initial = PlayerState(health: 5, bonusPoints: 0)

    nonisolated static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
        lhs.health == rhs.health && lhs.bonusPoints == rhs.bonusPoints
    }
}

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

    /// Считает игрока погибшим.
    static func isDead(_ state: PlayerState) -> Bool {
        state.health <= 0
    }
}
