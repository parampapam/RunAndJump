//
//  GameProgressTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 13.05.2026.
//

import Testing
@testable import RunAndJump

struct GameProgressTests {

    @Test func initialProgress() {
        let p = GameProgress.initial
        #expect(p.currentLevelIndex == 0)
        #expect(p.carriedBonusPoints == 0)
        #expect(p.activeCheckpointIndex == nil)
        #expect(p.collectedPickupIndices.isEmpty)
    }

    /// Точки восстановления у каждого уровня свои — на новом уровне игрок
    /// начинает со старта, даже если на предыдущем поднял последний флаг.
    @Test func levelCompletionResetsCheckpoint() {
        let progress = GameProgress(currentLevelIndex: 0,
                                    carriedBonusPoints: 0,
                                    activeCheckpointIndex: 2)

        let newProgress = GameProgressRules.levelCompleted(
            progress: progress,
            finalState: PlayerState(health: 100, bonusPoints: 15)
        )

        #expect(newProgress.activeCheckpointIndex == nil)
    }

    @Test func levelCompletionCarriesBonusAndAdvances() {
        let progress = GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0)
        let finalState = PlayerState(health: 3, bonusPoints: 15)

        let newProgress = GameProgressRules.levelCompleted(
            progress: progress,
            finalState: finalState
        )

        #expect(newProgress.currentLevelIndex == 1)
        #expect(newProgress.carriedBonusPoints == 15)
    }

    @Test func subsequentLevelCarriesAccumulatedBonus() {
        let progress = GameProgress(currentLevelIndex: 1, carriedBonusPoints: 15)
        let finalState = PlayerState(health: 2, bonusPoints: 40)

        let newProgress = GameProgressRules.levelCompleted(
            progress: progress,
            finalState: finalState
        )

        #expect(newProgress.currentLevelIndex == 2)
        #expect(newProgress.carriedBonusPoints == 40)
    }

    @Test func gameCompletionAfterLastLevel() {
        let p = GameProgress(currentLevelIndex: 3, carriedBonusPoints: 100)
        #expect(GameProgressRules.isGameCompleted(progress: p, totalLevels: 3) == true)
    }

    @Test func gameNotCompletedInMiddle() {
        let p = GameProgress(currentLevelIndex: 1, carriedBonusPoints: 30)
        #expect(GameProgressRules.isGameCompleted(progress: p, totalLevels: 3) == false)
    }

    // MARK: - Гибель

    @Test func deathCarriesBonusCollectedDuringLevel() {
        let progress = GameProgress(currentLevelIndex: 1, carriedBonusPoints: 30)
        // На уровне игрок успел набрать ещё 25 очков.
        let atDeath = PlayerState(health: 0, bonusPoints: 55)

        let newProgress = GameProgressRules.playerDied(progress: progress, finalState: atDeath)

        #expect(newProgress.carriedBonusPoints == 55)
        // Уровень тот же — гибель не двигает игрока вперёд.
        #expect(newProgress.currentLevelIndex == 1)
    }

    @Test func deathKeepsCheckpointAndCollectedPickups() {
        let progress = GameProgress(currentLevelIndex: 0,
                                    carriedBonusPoints: 0,
                                    activeCheckpointIndex: 1,
                                    collectedPickupIndices: [0, 3])

        let newProgress = GameProgressRules.playerDied(
            progress: progress,
            finalState: PlayerState(health: 0, bonusPoints: 25)
        )

        #expect(newProgress.activeCheckpointIndex == 1)
        #expect(newProgress.collectedPickupIndices == [0, 3])
    }

    /// Здоровье не переносится через гибель — оно всегда стартовое, поэтому
    /// аптечки и должны возвращаться на сцену.
    @Test func respawnRestoresHealthButKeepsBonus() {
        let progress = GameProgressRules.playerDied(
            progress: GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0),
            finalState: PlayerState(health: 0, bonusPoints: 40)
        )

        let state = GameProgressRules.initialPlayerState(for: progress)

        #expect(state.health == HealthConfiguration.standard.initial)
        #expect(state.bonusPoints == 40)
    }

    @Test func levelCompletionClearsCollectedPickups() {
        let progress = GameProgress(currentLevelIndex: 0,
                                    carriedBonusPoints: 0,
                                    activeCheckpointIndex: 2,
                                    collectedPickupIndices: [0, 1, 2])

        let newProgress = GameProgressRules.levelCompleted(
            progress: progress,
            finalState: PlayerState(health: 100, bonusPoints: 15)
        )

        // Индексы наград у каждого уровня свои — список должен обнулиться.
        #expect(newProgress.collectedPickupIndices.isEmpty)
    }

    @Test func initialPlayerStateResetsHealthAndKeepsBonus() {
        let progress = GameProgress(currentLevelIndex: 2, carriedBonusPoints: 35)
        let initial = GameProgressRules.initialPlayerState(for: progress)
        #expect(initial.health == HealthConfiguration.standard.initial)
        #expect(initial.bonusPoints == 35)
    }
}
