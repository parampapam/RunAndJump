//
//  JumpControllerLadderTests.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 25.05.2026.
//

import Testing
@testable import RunAndJump

@Suite("JumpController — прыжок с лестницы")
struct JumpControllerLadderTests {
    
    @Test("После отпускания лестницы прыжок разрешён")
    func jumpAllowedAfterReleasingLadder() {
        var controller = JumpController()
        controller.didReleaseLadder(at: 0)
        controller.didPressJump(at: 0)
        
        let jumped = controller.consumeJumpIfPossible(at: 0)
        #expect(jumped == true)
    }
    
    @Test("Прыжок с лестницы работает в пределах coyote time")
    func jumpAllowedWithinCoyoteAfterLadder() {
        var controller = JumpController()
        controller.coyoteDuration = 0.1
        controller.didReleaseLadder(at: 0)
        controller.didPressJump(at: 0.05)
        
        let jumped = controller.consumeJumpIfPossible(at: 0.05)
        #expect(jumped == true)
    }
    
    @Test("После истечения coyote time прыжок запрещён")
    func jumpForbiddenAfterCoyoteExpires() {
        var controller = JumpController()
        controller.coyoteDuration = 0.1
        controller.didReleaseLadder(at: 0)
        controller.didPressJump(at: 0.2)
        
        let jumped = controller.consumeJumpIfPossible(at: 0.2)
        #expect(jumped == false)
    }
    
    @Test("Jump buffering работает: нажал до отпускания лестницы — прыгнет сразу после")
    func bufferedJumpFiresOnLadderRelease() {
        var controller = JumpController()
        controller.jumpBufferDuration = 0.1
        // Игрок на лестнице, нажал прыжок
        controller.didPressJump(at: 0)
        // В том же кадре LadderController вернул .releaseLadder
        controller.didReleaseLadder(at: 0)
        
        let jumped = controller.consumeJumpIfPossible(at: 0)
        #expect(jumped == true)
    }
}
