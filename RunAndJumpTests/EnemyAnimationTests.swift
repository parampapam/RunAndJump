//
//  EnemyAnimationTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 26.07.2026.
//

import CoreGraphics
import Testing
@testable import RunAndJump

struct EnemyAnimationTests {

    @Test func movingRightFacesRight() {
        #expect(EnemyAnimation.facing(dx: 3, current: .left) == .right)
    }

    @Test func movingLeftFacesLeft() {
        #expect(EnemyAnimation.facing(dx: -3, current: .right) == .left)
    }

    /// На развороте и у неподвижных врагов сдвиг нулевой — направление держим.
    @Test(arguments: [EnemyFacing.left, .right])
    func standingStillKeepsFacing(current: EnemyFacing) {
        #expect(EnemyAnimation.facing(dx: 0, current: current) == current)
    }

    @Test(arguments: EnemyKind.allCases)
    func aliveAnimationHasFrames(kind: EnemyKind) {
        let frames = AnimationFrames.Enemy.frames(for: kind, state: .alive)
        #expect(frames.count > 1)                     // цикл, а не статичный кадр
        #expect(Set(frames).count == frames.count)    // кадры не повторяются
    }

    @Test(arguments: EnemyKind.allCases)
    func defeatedAnimationIsSingleFrame(kind: EnemyKind) {
        #expect(AnimationFrames.Enemy.frames(for: kind, state: .defeated).count == 1)
    }

    /// Кадры разных видов не пересекаются — иначе враг «превратился» бы в другого.
    @Test func kindsDoNotShareFrames() {
        let all = EnemyKind.allCases.flatMap {
            AnimationFrames.Enemy.frames(for: $0, state: .alive)
                + AnimationFrames.Enemy.frames(for: $0, state: .defeated)
        }
        #expect(Set(all).count == all.count)
    }

    @Test(arguments: EnemyKind.allCases)
    func frameDurationIsPositive(kind: EnemyKind) {
        #expect(AnimationDuration.Enemy.timePerFrame(for: kind) > 0)
    }
}
