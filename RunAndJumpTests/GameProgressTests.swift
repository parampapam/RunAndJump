//
//  GameProgressTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 13.05.2026.
//

import CoreGraphics
import Testing
@testable import RunAndJump

struct GameProgressTests {

    @Test func initialProgress() {
        let p = GameProgress.initial
        #expect(p.currentLevelIndex == 0)
        #expect(p.carriedBonusPoints == 0)
        #expect(p.activeCheckpointIndex == nil)
        #expect(p.collectedPickupIndices.isEmpty)
        #expect(p.defeatedEnemyIndices.isEmpty)
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

    // MARK: - Враги, возвращаемые на уровень

    private static let enemies: [EnemyDescriptor] = [
        .stationary(.plant, at: TileCoordinate(x: 10, y: 1)),   // 10 очков
        .patrolling(.imp, at: TileCoordinate(x: 28, y: 1),
                    leftX: 26, rightX: 30, speed: 120),         // 20 очков
    ]

    /// Враг вернётся на уровень — значит, очки за него не заработаны.
    @Test func deathTakesBackPointsForRestoredEnemies() {
        let progress = GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0)
        // 50 очков, из них 20 — за беса, который сейчас вернётся.
        let atDeath = PlayerState(health: 0, bonusPoints: 50)

        let newProgress = GameProgressRules.playerDied(
            progress: progress,
            finalState: atDeath,
            restoredEnemies: [1],
            enemies: Self.enemies
        )

        #expect(newProgress.carriedBonusPoints == 30)
    }

    /// Победы, засчитанные флагом, не возвращаются и очков не стоят.
    @Test func deathKeepsPointsForEnemiesConfirmedByCheckpoint() {
        let progress = GameProgressRules.checkpointReached(
            progress: GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0),
            index: 0,
            defeatedSinceCheckpoint: [0, 1]
        )

        let newProgress = GameProgressRules.playerDied(
            progress: progress,
            finalState: PlayerState(health: 0, bonusPoints: 50),
            restoredEnemies: [],
            enemies: Self.enemies
        )

        #expect(newProgress.carriedBonusPoints == 50)
        #expect(newProgress.defeatedEnemyIndices == [0, 1])
    }

    @Test func checkpointConfirmsDefeatsAndMovesRespawnPoint() {
        var progress = GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0)

        progress = GameProgressRules.checkpointReached(
            progress: progress, index: 0, defeatedSinceCheckpoint: [0]
        )
        progress = GameProgressRules.checkpointReached(
            progress: progress, index: 1, defeatedSinceCheckpoint: [1]
        )

        // Второй флаг не отменяет засчитанное первым.
        #expect(progress.activeCheckpointIndex == 1)
        #expect(progress.defeatedEnemyIndices == [0, 1])
    }

    /// Счёт не уходит в минус, даже если очки за врага уже потрачены смертью
    /// раньше (описание уровня изменилось между запусками и т. п.).
    @Test func refundNeverDrivesScoreNegative() {
        let newProgress = GameProgressRules.playerDied(
            progress: GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0),
            finalState: PlayerState(health: 0, bonusPoints: 5),
            restoredEnemies: [0, 1],
            enemies: Self.enemies
        )

        #expect(newProgress.carriedBonusPoints == 0)
    }

    @Test func levelCompletionClearsDefeatedEnemies() {
        let progress = GameProgress(currentLevelIndex: 0,
                                    carriedBonusPoints: 0,
                                    defeatedEnemyIndices: [0, 1])

        let newProgress = GameProgressRules.levelCompleted(
            progress: progress,
            finalState: PlayerState(health: 100, bonusPoints: 15)
        )

        #expect(newProgress.defeatedEnemyIndices.isEmpty)
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

    // MARK: - Перезапуск уровня из паузы

    /// Уровень собирается как при первом входе: флаги опущены, награды и враги
    /// на местах.
    @Test func levelRestartResetsPerLevelState() {
        let progress = GameProgress(currentLevelIndex: 1,
                                    carriedBonusPoints: 60,
                                    activeCheckpointIndex: 2,
                                    collectedPickupIndices: [0, 4],
                                    defeatedEnemyIndices: [1],
                                    bonusPointsAtLevelStart: 40)

        let restarted = GameProgressRules.levelRestarted(progress: progress)

        #expect(restarted.currentLevelIndex == 1)
        #expect(restarted.activeCheckpointIndex == nil)
        #expect(restarted.collectedPickupIndices.isEmpty)
        #expect(restarted.defeatedEnemyIndices.isEmpty)
    }

    /// Награды возвращаются на уровень — значит и очки за них должны уйти,
    /// иначе перезапуск уровня стал бы бесконечной фермой очков.
    @Test func levelRestartRollsBonusBackToLevelStart() {
        let progress = GameProgress(currentLevelIndex: 1,
                                    carriedBonusPoints: 95,
                                    bonusPointsAtLevelStart: 40)

        let restarted = GameProgressRules.levelRestarted(progress: progress)

        #expect(restarted.carriedBonusPoints == 40)
        // Значение переживает перезапуск: перезапустить уровень можно и дважды.
        #expect(restarted.bonusPointsAtLevelStart == 40)
    }

    /// Сохранение прошлой сборки не знает очков на входе в уровень — откатывать
    /// не к чему, счёт остаётся как есть.
    @Test func levelRestartKeepsBonusWhenLevelStartIsUnknown() {
        let progress = GameProgress(currentLevelIndex: 1,
                                    carriedBonusPoints: 95,
                                    bonusPointsAtLevelStart: nil)

        #expect(GameProgressRules.levelRestarted(progress: progress).carriedBonusPoints == 95)
    }

    /// Очки на выходе с уровня — это очки на входе в следующий.
    @Test func levelCompletionRecordsBonusAtLevelStart() {
        let newProgress = GameProgressRules.levelCompleted(
            progress: GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0),
            finalState: PlayerState(health: 100, bonusPoints: 15)
        )

        #expect(newProgress.bonusPointsAtLevelStart == 15)
    }

    /// Гибель и флаг счёт на входе в уровень не трогают — уровень тот же.
    @Test func deathAndCheckpointKeepBonusAtLevelStart() {
        let progress = GameProgress(currentLevelIndex: 1,
                                    carriedBonusPoints: 40,
                                    bonusPointsAtLevelStart: 40)

        let afterCheckpoint = GameProgressRules.checkpointReached(
            progress: progress, index: 0, defeatedSinceCheckpoint: []
        )
        let afterDeath = GameProgressRules.playerDied(
            progress: afterCheckpoint,
            finalState: PlayerState(health: 0, bonusPoints: 75)
        )

        #expect(afterDeath.bonusPointsAtLevelStart == 40)
    }

    // MARK: - Есть ли что продолжать

    @Test func nothingToResumeWithoutASave() {
        #expect(GameProgressRules.isResumable(nil, totalLevels: 3) == false)
    }

    /// Сохранение, совпадающее с началом игры, продолжать нечего.
    @Test func nothingToResumeAtTheVeryBeginning() {
        #expect(GameProgressRules.isResumable(.initial, totalLevels: 3) == false)
    }

    @Test func startedGameIsResumable() {
        let saved = GameProgress(currentLevelIndex: 1,
                                 carriedBonusPoints: 40,
                                 activeCheckpointIndex: 0)
        #expect(GameProgressRules.isResumable(saved, totalLevels: 3) == true)
    }

    /// Негодное сохранение (уровня больше нет) продолжать нельзя — запуск
    /// начнёт новую игру, и окно паузы было бы враньём.
    @Test func unusableSaveIsNotResumable() {
        let saved = GameProgress(currentLevelIndex: 7, carriedBonusPoints: 40)
        #expect(GameProgressRules.isResumable(saved, totalLevels: 3) == false)
    }

    @Test func initialPlayerStateResetsHealthAndKeepsBonus() {
        let progress = GameProgress(currentLevelIndex: 2, carriedBonusPoints: 35)
        let initial = GameProgressRules.initialPlayerState(for: progress)
        #expect(initial.health == HealthConfiguration.standard.initial)
        #expect(initial.bonusPoints == 35)
    }
}
