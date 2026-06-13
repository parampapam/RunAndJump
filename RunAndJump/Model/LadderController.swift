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

    /// Насколько сильно нужно отклонить ввод по вертикали, чтобы НАЧАТЬ лазание.
    /// Защищает от случайного «примагничивания» к лестнице, когда игрок просто
    /// проходит мимо, держа стик вбок: у джойстика всегда есть небольшой
    /// вертикальный дрейф, и без порога он мгновенно цеплялся бы за лестницу.
    /// На скорость уже идущего лазания не влияет — там работает любой ввод.
    var climbStartThreshold: CGFloat = 0.5

    // MARK: Состояние

    /// Сейчас игрок находится на лестнице (в режиме climbing).
    private(set) var isClimbing: Bool = false

    /// Игрок прямо сейчас касается хотя бы одной лестницы.
    private var isTouchingLadder: Bool = false

    /// Игрок прямо сейчас стоит на земле (контакт с категорией ground).
    /// Нужно, чтобы отпускать лестницу при спуске до пола и не цепляться
    /// «вниз» у её основания.
    private var isGrounded: Bool = false

    /// Текущий аналоговый вертикальный ввод в [-1, 1]: знак — направление
    /// (+ вверх, − вниз), модуль — доля скорости лазания.
    private var verticalInput: CGFloat = 0

    // MARK: События контактов с лестницей

    mutating func didTouchLadder() {
        isTouchingLadder = true
    }

    mutating func didLeaveLadder() {
        isTouchingLadder = false
    }

    // MARK: События контактов с землёй

    mutating func didTouchGround() {
        isGrounded = true
    }

    mutating func didLeaveGround() {
        isGrounded = false
    }

    // MARK: События ввода

    /// Задаёт аналоговый вертикальный ввод в [-1, 1] (+ вверх, − вниз).
    /// Значение уже очищено от мёртвой зоны источником ввода. Начать лазание
    /// можно лишь при отклонении не меньше `climbStartThreshold` (чтобы дрейф
    /// стика при ходьбе вбок не цеплял за лестницу); скорость уже идущего
    /// лазания масштабируется любым ненулевым значением.
    mutating func setVerticalInput(_ value: CGFloat) {
        verticalInput = value
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

        // Спустились по лестнице и упёрлись в землю — отпускаем лестницу, чтобы
        // можно было идти вбок (а не висеть, пока не прыгнешь). Срабатывает,
        // только когда игрок не лезет ВВЕРХ осознанно — иначе начало подъёма с
        // земли сразу же отцеплялось бы.
        if isClimbing && isGrounded && verticalInput < climbStartThreshold {
            isClimbing = false
            return .releaseLadder
        }

        // Не на лестнице, но касаемся и игрок осознанно отклонил ввод по
        // вертикали (сильнее порога) — цепляемся и центрируемся. Лёгкий дрейф
        // стика при ходьбе вбок порог не проходит, поэтому мимо лестницы можно
        // спокойно пройти. С земли цепляемся только при движении ВВЕРХ (вниз
        // некуда — там опора), иначе толчок вниз у основания лестницы дёргал бы
        // climbing каждый кадр. В воздухе цепляемся и вверх, и вниз.
        if !isClimbing && isTouchingLadder {
            let wantsUp = verticalInput >= climbStartThreshold
            let wantsDown = verticalInput <= -climbStartThreshold
            if wantsUp || (wantsDown && !isGrounded) {
                isClimbing = true
                return .startClimbing
            }
        }

        // На лестнице — лезем (или висим, если ввода нет).
        if isClimbing {
            return .climb(verticalVelocity: verticalInput * climbSpeed)
        }

        return .idle
    }
}
