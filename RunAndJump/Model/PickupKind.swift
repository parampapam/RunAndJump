//
//  PickupKind.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 25.07.2026.
//

import Foundation

/// Достоинство монеты. Номинал очков задаётся здесь — единственный
/// источник значения и для правил игры, и для расстановки на уровнях.
enum CoinTier: CaseIterable, Equatable {
    case bronze
    case silver
    case gold

    /// Очки, начисляемые за монету этого достоинства.
    var points: Int {
        switch self {
        case .bronze: return 5
        case .silver: return 10
        case .gold:   return 20
        }
    }
}

/// Вид подбираемой награды (runtime-свойство узла `Pickup`).
/// Новая категория бонуса — это новый case здесь плюс маппинг
/// в `event` и кадры анимации в `AnimationFrames.Pickup`.
enum PickupKind: Equatable {
    case health
    case coin(CoinTier)

    /// Игровое событие, которое порождает подбор этой награды.
    /// Сцена не разбирает виды наград — она просто применяет событие.
    var event: GameEvent {
        switch self {
        case .health:
            return .healthPickup
        case .coin(let tier):
            return .bonusPickup(points: tier.points)
        }
    }
}
