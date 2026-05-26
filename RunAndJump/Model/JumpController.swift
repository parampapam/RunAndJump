//
//  JumpController.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 07.05.2026.
//

import Foundation

/// Управляет логикой "когда можно прыгнуть": coyote time + jump buffering.
struct JumpController {

    // MARK: Конфигурация

    /// Сколько секунд после потери контакта с землёй прыжок ещё доступен.
    var coyoteDuration: TimeInterval = 0.1

    /// Сколько секунд "помним" нажатие прыжка, ожидая приземления.
    var jumpBufferDuration: TimeInterval = 0.1

    // MARK: Состояние

    /// Время последнего контакта с землёй. nil — никогда не касался.
    private var lastGroundedTime: TimeInterval?

    /// Касается ли земли прямо сейчас.
    private(set) var isGrounded: Bool = false

    /// Время последнего нажатия кнопки прыжка, ожидающего реализации.
    private var pendingJumpTime: TimeInterval?

    // MARK: События

    mutating func didTouchGround(at time: TimeInterval) {
        isGrounded = true
        lastGroundedTime = time
    }

    mutating func didLeaveGround(at time: TimeInterval) {
        isGrounded = false
        lastGroundedTime = time
    }

    mutating func didPressJump(at time: TimeInterval) {
        pendingJumpTime = time
    }

    /// Вызывается каждый кадр. Возвращает true, если прямо сейчас нужно прыгнуть.
    /// При срабатывании сбрасывает буферизованное нажатие.
    mutating func consumeJumpIfPossible(at time: TimeInterval) -> Bool {
        guard let pressTime = pendingJumpTime else { return false }

        // Нажатие слишком давнее — забываем.
        if time - pressTime > jumpBufferDuration {
            pendingJumpTime = nil
            return false
        }

        // Можем прыгнуть, если стоим на земле или были на земле недавно.
        let canJump: Bool
        if isGrounded {
            canJump = true
        } else if let groundedTime = lastGroundedTime {
            canJump = (time - groundedTime) <= coyoteDuration
        } else {
            canJump = false
        }

        if canJump {
            pendingJumpTime = nil
            // После прыжка сразу считаемся не на земле,
            // чтобы повторное нажатие в течение coyote time не дало двойной прыжок.
            isGrounded = false
            lastGroundedTime = nil
            return true
        }

        return false
    }

    /// Игрок отпустил лестницу. С этого момента прыжок разрешён
    /// в течение `coyoteDuration` секунд — так же, как после ухода с земли.
    mutating func didReleaseLadder(at time: TimeInterval) {
        isGrounded = false
        lastGroundedTime = time
    }
}
