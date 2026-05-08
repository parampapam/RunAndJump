//
//  JumpControllerTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 07.05.2026.
//

import Testing
@testable import RunAndJump

struct JumpControllerTests {

    @Test func jumpsWhenGrounded() {
        var jc = JumpController()
        jc.didTouchGround(at: 0)
        jc.didPressJump(at: 0.5)
        #expect(jc.consumeJumpIfPossible(at: 0.5) == true)
    }

    @Test func doesNotJumpWhenInAir() {
        var jc = JumpController()
        // Никогда не касался земли.
        jc.didPressJump(at: 1.0)
        #expect(jc.consumeJumpIfPossible(at: 1.0) == false)
    }

    @Test func coyoteTimeAllowsLateJump() {
        var jc = JumpController()
        jc.didTouchGround(at: 0)
        jc.didLeaveGround(at: 1.0)
        jc.didPressJump(at: 1.05) // через 50 мс после ухода — допустимо
        #expect(jc.consumeJumpIfPossible(at: 1.05) == true)
    }

    @Test func coyoteTimeExpires() {
        var jc = JumpController()
        jc.didTouchGround(at: 0)
        jc.didLeaveGround(at: 1.0)
        jc.didPressJump(at: 1.2) // через 200 мс — слишком поздно
        #expect(jc.consumeJumpIfPossible(at: 1.2) == false)
    }

    @Test func jumpBufferingTriggersOnLanding() {
        var jc = JumpController()
        // Игрок в воздухе, нажал прыжок чуть раньше приземления.
        jc.didPressJump(at: 1.0)
        #expect(jc.consumeJumpIfPossible(at: 1.0) == false)
        // Через 50 мс приземлился.
        jc.didTouchGround(at: 1.05)
        #expect(jc.consumeJumpIfPossible(at: 1.05) == true)
    }

    @Test func jumpBufferExpires() {
        var jc = JumpController()
        jc.didPressJump(at: 1.0)
        // Приземлился слишком поздно — нажатие забыто.
        jc.didTouchGround(at: 1.2)
        #expect(jc.consumeJumpIfPossible(at: 1.2) == false)
    }

    @Test func cannotDoubleJump() {
        var jc = JumpController()
        jc.didTouchGround(at: 0)
        jc.didPressJump(at: 0)
        #expect(jc.consumeJumpIfPossible(at: 0) == true)
        // Сразу пытаемся прыгнуть ещё раз — нельзя.
        jc.didPressJump(at: 0.05)
        #expect(jc.consumeJumpIfPossible(at: 0.05) == false)
    }

    @Test func dithering_doesNotBreakGroundedState() {
        // Симулируем дрожание: контакт пропадает и сразу восстанавливается.
        var jc = JumpController()
        jc.didTouchGround(at: 0)
        jc.didLeaveGround(at: 0.016)   // через кадр пропал
        jc.didTouchGround(at: 0.032)   // через кадр восстановился
        jc.didPressJump(at: 0.04)
        // Должны прыгнуть — контакт фактически не терялся надолго.
        #expect(jc.consumeJumpIfPossible(at: 0.04) == true)
    }
}
