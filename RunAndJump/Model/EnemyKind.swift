//
//  EnemyKind.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 26.07.2026.
//

import CoreGraphics

/// Вид врага. Определяет и внешний вид (кадры анимации в `AnimationFrames.Enemy`),
/// и стиль движения: типов движения по-прежнему два, но вариантов врага больше.
/// Новый враг — это новый case здесь плюс кадры в `AnimationFrames.Enemy`.
enum EnemyKind: CaseIterable, Equatable {
    case crab
    case imp
    case sniper
    case plant
    case wasp

    /// Стиль движения врага. Именно вид решает, ходит враг или стоит на месте, —
    /// поэтому уровень не может случайно заставить растение патрулировать.
    var movementStyle: EnemyMovementStyle {
        switch self {
        case .crab, .imp, .sniper:
            return .patrolling
        case .plant, .wasp:
            return .stationary
        }
    }

    /// Очки за прыжок врагу на голову. Номинал задаётся здесь — единственный
    /// источник и для правил игры, и для будущей витрины «сколько кто стоит».
    /// Шкала — по сложности попадания: растение стоит на месте у земли, оса
    /// висит на высоте, снайпер вдобавок быстрый.
    var defeatPoints: Int {
        switch self {
        case .plant:  return 10
        case .crab:   return 15
        case .imp:    return 20
        case .wasp:   return 25
        case .sniper: return 30
        }
    }

    /// Игровое событие, которое порождает победа над этим врагом.
    /// Сцена не разбирает виды врагов — она просто применяет событие.
    var defeatEvent: GameEvent {
        .enemyDefeated(points: defeatPoints)
    }
}

/// Как враг перемещается по уровню. Типов ровно два — им соответствуют
/// стратегии `PatrollingMovement` и `StationaryMovement` в слое сцены.
enum EnemyMovementStyle: Equatable {
    case stationary
    case patrolling
}

/// Итоговое поведение врага: стиль движения вместе с его параметрами.
/// Строится из `EnemyDescriptor` (см. `EnemyDescriptor.behavior`), а `LevelBuilder`
/// уже переводит его в конкретную стратегию движения.
enum EnemyBehavior: Equatable {
    case stationary
    /// Патруль между двумя X. `leftX`/`rightX` — диапазон X **нижнего-левого
    /// угла** врага в тайлах; `speed` — скорость в пунктах/с.
    case patrolling(leftX: CGFloat, rightX: CGFloat, speed: CGFloat)
}
