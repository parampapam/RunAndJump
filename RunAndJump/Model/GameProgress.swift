//
//  GameProgress.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import Foundation

/// Состояние прогресса игрока через все уровни.
/// Чистая модель — не зависит от SpriteKit.
struct GameProgress: Equatable {
    var currentLevelIndex: Int
    var carriedBonusPoints: Int

    static let initial = GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0)
}

enum GameProgressRules {

    /// После успешного прохождения уровня: переносим бонусы, инкрементируем индекс.
    static func levelCompleted(progress: GameProgress, finalState: PlayerState) -> GameProgress {
        GameProgress(
            currentLevelIndex: progress.currentLevelIndex + 1,
            carriedBonusPoints: finalState.bonusPoints
        )
    }

    /// Признак, что игрок прошёл все уровни.
    static func isGameCompleted(progress: GameProgress, totalLevels: Int) -> Bool {
        progress.currentLevelIndex >= totalLevels
    }

    /// Создаёт начальное состояние игрока для нового уровня:
    /// здоровье сбрасывается, бонусы переносятся.
    static func initialPlayerState(for progress: GameProgress) -> PlayerState {
        PlayerState(health: 5, bonusPoints: progress.carriedBonusPoints, locomotionMode: .normal)
    }
}
