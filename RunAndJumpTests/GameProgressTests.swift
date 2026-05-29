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

    @Test func initialPlayerStateResetsHealthAndKeepsBonus() {
        let progress = GameProgress(currentLevelIndex: 2, carriedBonusPoints: 35)
        let initial = GameProgressRules.initialPlayerState(for: progress)
        #expect(initial.health == 5)
        #expect(initial.bonusPoints == 35)
    }
}
