//
//  LadderController.swift
//  RunAndJump
//
//  Created by Roman Pospelov on [сегодня].
//

import Foundation

/// Решение контроллера
enum LadderAction: Equatable {
    /// Прицепиться к лестнице (перевести персонажа в режим .climbing).
    case startClimbing
    /// Продолжить лезть с заданной вертикальной скоростью (может быть 0 — висеть).
    case climb(verticalVelocity: CGFloat)
    /// Отпустить лестницу (перевести персонажа в режим .normal).
    case releaseLadder
    /// Ничего не делать.
    case idle
}

/// Управляет логикой передвижения по лестнице.
/// Слушает события ввода и контактов, в `update(...)` сообщает,
/// что нужно сделать в этом кадре.
struct LadderController {

    // MARK: Конфигурация

    /// Скорость лазания по лестнице в точках в секунду.
    var climbSpeed: CGFloat = 120

    // MARK: Состояние

    /// Сейчас игрок находится на лестнице (в режиме climbing).
    private(set) var isClimbing: Bool = false

    /// Игрок прямо сейчас касается хотя бы одной лестницы.
    private var isTouchingLadder: Bool = false

    /// Текущий вертикальный ввод: -1 (вниз), 0 (ничего), +1 (вверх).
    private var verticalInput: CGFloat = 0

    // MARK: События контактов с лестницей

    mutating func didTouchLadder() {
        isTouchingLadder = true
    }

    mutating func didLeaveLadder() {
        isTouchingLadder = false
    }

    // MARK: События ввода

    mutating func didPressUp() {
        verticalInput = 1
    }

    mutating func didPressDown() {
        verticalInput = -1
    }

    mutating func didReleaseVertical() {
        verticalInput = 0
    }

    // MARK: События со стороны других контроллеров

    /// Игрок прыгнул с лестницы (через JumpController).
    /// Сбрасывает состояние climbing — но не вызывает LadderAction,
    /// потому что прыжок уже обработан JumpController-ом.
    mutating func didJumpOffLadder() {
        isClimbing = false
    }

    // MARK: Игровой цикл

    /// Вызывается каждый кадр. Возвращает действие, которое нужно
    /// применить к игроку.
    mutating func update() -> LadderAction {
        // Уже на лестнице, но больше не касаемся — слез сверху или снизу.
        if isClimbing && !isTouchingLadder {
            isClimbing = false
            return .releaseLadder
        }

        // Не на лестнице, но касаемся и игрок дал вертикальный ввод — цепляемся.
        if !isClimbing && isTouchingLadder && verticalInput != 0 {
            isClimbing = true
            return .startClimbing
        }

        // На лестнице — лезем (или висим, если ввода нет).
        if isClimbing {
            return .climb(verticalVelocity: verticalInput * climbSpeed)
        }

        return .idle
    }
}
