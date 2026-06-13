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

    /// Допуск, в пределах которого ступни считаются «у основания лестницы».
    /// Небольшой запас сглаживает дрожь физики и перелёт за кадр на спуске.
    var bottomTolerance: CGFloat = 2

    // MARK: Состояние

    /// Сейчас игрок находится на лестнице (в режиме climbing).
    private(set) var isClimbing: Bool = false

    /// Игрок прямо сейчас касается хотя бы одной лестницы.
    private var isTouchingLadder: Bool = false

    /// Y нижнего края текущей лестницы (её основание — верх земли или платформы,
    /// на которой она стоит). Обновляется при касании лестницы.
    private var ladderBottomY: CGFloat = 0

    /// Текущий аналоговый вертикальный ввод в [-1, 1]: знак — направление
    /// (+ вверх, − вниз), модуль — доля скорости лазания.
    private var verticalInput: CGFloat = 0

    // MARK: События контактов с лестницей

    /// - Parameter bottomY: Y нижнего края лестницы (её основания).
    mutating func didTouchLadder(bottomY: CGFloat) {
        isTouchingLadder = true
        ladderBottomY = bottomY
    }

    mutating func didLeaveLadder() {
        isTouchingLadder = false
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

    /// Вызывается каждый кадр.
    /// - Parameter playerFeetY: Y нижней грани игрока («ступни»). По нему
    ///   геометрически определяем, дошёл ли игрок до основания лестницы —
    ///   это работает для любой опоры (земля или платформа), тогда как сквозь
    ///   платформы в режиме лазания игрок проходит и физический контакт с ними
    ///   не годится как признак «спустился до низа».
    /// - Returns: действие, которое нужно применить к игроку.
    mutating func update(playerFeetY: CGFloat) -> LadderAction {
        // Ступни на уровне основания (или чуть ниже от перелёта за кадр).
        let atBottom = playerFeetY <= ladderBottomY + bottomTolerance

        // Уже на лестнице, но больше не касаемся — слез сверху.
        if isClimbing && !isTouchingLadder {
            isClimbing = false
            return .releaseLadder
        }

        // Спустились до основания лестницы (земли или платформы) — отпускаем,
        // чтобы можно было идти вбок (а не висеть, пока не прыгнешь). Срабатывает
        // только когда игрок не лезет ВВЕРХ осознанно — иначе начало подъёма
        // снизу сразу же отцеплялось бы.
        if isClimbing && atBottom && verticalInput < climbStartThreshold {
            isClimbing = false
            return .releaseLadder
        }

        // Не на лестнице, но касаемся и игрок осознанно отклонил ввод по
        // вертикали (сильнее порога) — цепляемся и центрируемся. Лёгкий дрейф
        // стика при ходьбе вбок порог не проходит, поэтому мимо лестницы можно
        // спокойно пройти. У основания цепляемся только при движении ВВЕРХ (вниз
        // некуда — там опора), иначе толчок вниз у низа лестницы дёргал бы
        // climbing каждый кадр. Выше основания цепляемся и вверх, и вниз.
        if !isClimbing && isTouchingLadder {
            let wantsUp = verticalInput >= climbStartThreshold
            let wantsDown = verticalInput <= -climbStartThreshold
            if wantsUp || (wantsDown && !atBottom) {
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
