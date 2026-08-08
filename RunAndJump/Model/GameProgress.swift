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
    /// Индекс пройденной точки восстановления в `LevelConfiguration.checkpoints`
    /// текущего уровня; `nil` — игрок ещё не миновал ни одного флага и
    /// возрождается на старте уровня.
    ///
    /// Живёт здесь, потому что гибель пересоздаёт сцену, а `GameProgress` —
    /// единственное, что переживает пересоздание. При переходе на следующий
    /// уровень сбрасывается: индексы точек у каждого уровня свои.
    var activeCheckpointIndex: Int? = nil
    /// Индексы уже поднятых наград в `LevelConfiguration.pickups` текущего
    /// уровня — тех, что не возвращаются после гибели (см.
    /// `PickupKind.staysCollectedAfterDeath`). Аптечки сюда не попадают.
    ///
    /// Живёт здесь по той же причине, что и точка восстановления: сцена
    /// пересобирает уровень с нуля, и без этого списка монеты, за которые очки
    /// уже начислены, можно было бы собрать повторно.
    var collectedPickupIndices: Set<Int> = []

    static let initial = GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0)
}

enum GameProgressRules {

    /// После успешного прохождения уровня: переносим бонусы, инкрементируем
    /// индекс. Точка восстановления сбрасывается — на новом уровне свои флаги,
    /// и игрок начинает его со старта.
    static func levelCompleted(progress: GameProgress, finalState: PlayerState) -> GameProgress {
        GameProgress(
            currentLevelIndex: progress.currentLevelIndex + 1,
            carriedBonusPoints: finalState.bonusPoints,
            activeCheckpointIndex: nil,
            collectedPickupIndices: []
        )
    }

    /// После гибели: уровень начинается заново от точки восстановления, но
    /// набранные очки остаются — они переходят в перенос, как при завершении
    /// уровня. Здоровье при этом восстанавливается до стартового
    /// (`initialPlayerState`), а список поднятых монет не трогаем: очки за них
    /// уже сохранены, второй раз их подобрать нельзя.
    static func playerDied(progress: GameProgress, finalState: PlayerState) -> GameProgress {
        var updated = progress
        updated.carriedBonusPoints = finalState.bonusPoints
        return updated
    }

    /// Признак, что игрок прошёл все уровни.
    static func isGameCompleted(progress: GameProgress, totalLevels: Int) -> Bool {
        progress.currentLevelIndex >= totalLevels
    }

    /// Создаёт начальное состояние игрока для нового уровня:
    /// здоровье сбрасывается до стартового запаса, бонусы переносятся.
    static func initialPlayerState(
        for progress: GameProgress,
        health configuration: HealthConfiguration = .standard
    ) -> PlayerState {
        PlayerState(health: configuration.initial, bonusPoints: progress.carriedBonusPoints)
    }
}
