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

    /// Минимальная пауза между прыжками. Защищает от двойного прыжка тем же
    /// нажатием/контактом: сразу после импульса игрок ещё кадр-два формально
    /// касается земли, плюс действует coyote-окно. Достаточно перекрыть оба —
    /// и заметно меньше длительности реального прыжкового прыжка, так что
    /// быстрые повторные прыжки после приземления не страдают.
    var rejumpLockout: TimeInterval = 0.2

    // MARK: Состояние

    /// Время последнего контакта с землёй. nil — никогда не касался.
    private var lastGroundedTime: TimeInterval?

    /// Касается ли земли прямо сейчас.
    private(set) var isGrounded: Bool = false

    /// Время последнего нажатия кнопки прыжка, ожидающего реализации.
    private var pendingJumpTime: TimeInterval?

    /// Время последнего совершённого прыжка — основа локаута повторного прыжка.
    private var lastJumpTime: TimeInterval?

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

        // Только что прыгнули — короткий локаут, чтобы то же нажатие/контакт не
        // дали второй прыжок. Нажатие НЕ сбрасываем: вдруг локаут спадёт, пока
        // буфер ещё жив — это штатный jump buffering.
        if let lastJump = lastJumpTime, time - lastJump < rejumpLockout {
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
            // Запоминаем момент прыжка для локаута. Состояние grounded НЕ трогаем —
            // оно отражает реальные контакты. Иначе прыжок, не оторвавший игрока
            // от земли (платформа прижала сверху), навсегда «теряет» опору: contact
            // не прерывался, didTouchGround больше не придёт — и прыжок умирает.
            lastJumpTime = time
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
