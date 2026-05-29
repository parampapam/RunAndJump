//
//  PlayerState.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 05.05.2026.
//

import Foundation

/// Режим передвижения игрока. Определяет, какие правила физики
/// сейчас к нему применяются.
enum LocomotionMode: Equatable {
    /// Обычная физика: гравитация работает, прыжок зависит от контакта снизу.
    case normal
    /// На лестнице: гравитация отключена, вертикальная скорость задаётся вводом.
    case climbing
}

/// Состояние игрока
struct PlayerState: Equatable {
    var health: Int
    var bonusPoints: Int
    var locomotionMode: LocomotionMode

    static let initial = PlayerState(
        health: 5,
        bonusPoints: 0
    )

    init(health: Int, bonusPoints: Int) {
        self.health = health
        self.bonusPoints = bonusPoints
        self.locomotionMode = .normal
    }
}
