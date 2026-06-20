//
//  PlayerAnimationTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 20.06.2026.
//

import Testing
import CoreGraphics
@testable import RunAndJump

struct PlayerAnimationTests {

    // MARK: - state

    @Test func airborneIsJumpingRegardlessOfInput() {
        #expect(PlayerAnimation.state(isOnGround: false, horizontalInput: 0) == .jumping)
        #expect(PlayerAnimation.state(isOnGround: false, horizontalInput: 1) == .jumping)
        #expect(PlayerAnimation.state(isOnGround: false, horizontalInput: -0.4) == .jumping)
    }

    @Test func groundedWithoutInputIsIdle() {
        #expect(PlayerAnimation.state(isOnGround: true, horizontalInput: 0) == .idle)
    }

    @Test func groundedWithInputIsRunning() {
        #expect(PlayerAnimation.state(isOnGround: true, horizontalInput: 1) == .running)
        #expect(PlayerAnimation.state(isOnGround: true, horizontalInput: -0.2) == .running)
    }

    // MARK: - facing

    @Test func positiveInputFacesRight() {
        #expect(PlayerAnimation.facing(horizontalInput: 0.5, current: .left) == .right)
    }

    @Test func negativeInputFacesLeft() {
        #expect(PlayerAnimation.facing(horizontalInput: -0.5, current: .right) == .left)
    }

    @Test func zeroInputKeepsCurrentFacing() {
        #expect(PlayerAnimation.facing(horizontalInput: 0, current: .left) == .left)
        #expect(PlayerAnimation.facing(horizontalInput: 0, current: .right) == .right)
    }
}
