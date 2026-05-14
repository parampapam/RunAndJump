//
//  PlayerState.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 05.05.2026.
//

import Foundation

/// Состояние игрока
struct PlayerState: Equatable {
    var health: Int
    var bonusPoints: Int

    static let initial = PlayerState(health: 5, bonusPoints: 0)
}

