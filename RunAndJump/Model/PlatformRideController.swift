//
//  PlatformRideController.swift
//  RunAndJump
//
//  Created by Roman Pospelov on [сегодня].
//

import Foundation
import CoreGraphics

/// Решение контроллера на текущий кадр.
enum PlatformRideAction: Equatable {
    /// Перенести игрока в эту точку и обнулить его вертикальную скорость.
    case ride(targetPosition: CGPoint)
    /// Игрок не едет на подвижной платформе — ничего не делаем.
    case idle
}

/// Управляет логикой «игрок едет на подвижной платформе»: привязкой при
/// приземлении сверху, переносом игрока вместе с платформой, упором в бок
/// неподвижной платформы и кулдауном после прыжка.
///
/// Чистая геометрия и тайминг — никакого SpriteKit. Сцена держит хэндл узла
/// платформы и кормит контроллер скалярами, а затем применяет `PlatformRideAction`.
struct PlatformRideController {

    // MARK: Конфигурация

    /// Допуск по высоте: насколько ниже верхнего ребра ещё считается
    /// «приземлился сверху».
    var landingTolerance: CGFloat = 10

    /// Запрет на привязку сразу после прыжка — чтобы поднимающаяся платформа
    /// не зацепила взлетающего игрока.
    var attachCooldownAfterJump: TimeInterval = 0.25

    /// Сплошные рамки неподвижных платформ — преграды при переносе игрока.
    /// Ставится один раз при настройке уровня.
    var obstacles: [CGRect] = []

    // MARK: Состояние

    /// Игрок прямо сейчас едет на подвижной платформе.
    private(set) var isRiding: Bool = false

    /// Смещение игрока относительно центра платформы — фиксирует его в системе
    /// отсчёта платформы.
    private var rideOffset: CGPoint = .zero

    /// Время последнего прыжка — после него короткий запрет на привязку.
    private var lastJumpTime: TimeInterval = -1000

    // MARK: События

    /// Игрок прыгнул — отрываемся от платформы и запускаем кулдаун.
    mutating func didJump(at time: TimeInterval) {
        isRiding = false
        lastJumpTime = time
    }

    /// Попытка привязки при контакте с платформой. Возвращает `true`, если игрок
    /// действительно приземлился на неё СВЕРХУ (низ игрока у верхнего ребра) и не
    /// находится в кулдауне после прыжка. При ударе снизу низ игрока намного ниже
    /// ребра — привязки нет, физика отрабатывает отскок.
    mutating func tryAttach(
        platformPosition: CGPoint,
        platformSize: CGSize,
        playerPosition: CGPoint,
        playerSize: CGSize,
        at time: TimeInterval
    ) -> Bool {
        guard time - lastJumpTime > attachCooldownAfterJump else { return false }

        let platformTop = platformPosition.y + platformSize.height / 2
        let playerBottom = playerPosition.y - playerSize.height / 2
        guard playerBottom >= platformTop - landingTolerance else { return false }

        isRiding = true
        // X — где игрок встал вдоль платформы; Y — высота покоя над её верхним ребром.
        rideOffset = CGPoint(
            x: playerPosition.x - platformPosition.x,
            y: platformSize.height / 2 + playerSize.height / 2
        )
        return true
    }

    /// Контакт с платформой закончился — слезли.
    mutating func didLeavePlatform() {
        isRiding = false
    }

    // MARK: Кадр

    /// Вызывается каждый кадр ПОСЛЕ физического шага (из `didSimulatePhysics`),
    /// иначе солвер откатывает ручное смещение позиции и игрок отстаёт от платформы.
    /// Возвращает действие, которое нужно применить к игроку.
    mutating func resolveRide(
        platformPosition: CGPoint,
        playerPosition: CGPoint,
        playerSize: CGSize,
        horizontalInputVelocity: CGFloat,
        dt: TimeInterval
    ) -> PlatformRideAction {
        guard isRiding else { return .idle }

        // Ввод игрока смещает его в системе отсчёта платформы — движение
        // аддитивно к ходу платформы.
        if horizontalInputVelocity != 0 {
            rideOffset.x += horizontalInputVelocity * CGFloat(dt)
        }

        var target = CGPoint(
            x: platformPosition.x + rideOffset.x,
            y: platformPosition.y + rideOffset.y
        )
        // Неподвижная платформа на пути не даёт пронести игрока сквозь себя.
        target.x = blockedCarryX(
            target: target,
            currentX: playerPosition.x,
            playerSize: playerSize
        )
        // Возвращаем смещение к фактическому X: иначе ввод копится «за преградой»,
        // и когда target.x уедет за край статичной платформы, ограничение спадёт
        // и игрока выстрелит вперёд.
        rideOffset.x = target.x - platformPosition.x
        return .ride(targetPosition: target)
    }

    // MARK: Геометрия

    /// Ограничивает горизонтальный перенос игрока подвижной платформой, если на
    /// пути оказался бок неподвижной платформы. Возвращает допустимый X.
    private func blockedCarryX(
        target: CGPoint,
        currentX: CGFloat,
        playerSize: CGSize
    ) -> CGFloat {
        let movingRight = target.x > currentX
        let movingLeft = target.x < currentX
        guard movingRight || movingLeft else { return target.x }

        let halfW = playerSize.width / 2
        let halfH = playerSize.height / 2
        let epsilon: CGFloat = 1
        let top = target.y + halfH
        let bottom = target.y - halfH

        var resultX = target.x
        for frame in obstacles {
            // Только боковое перекрытие: если игрок стоит на верхнем ребре — не преграда.
            guard bottom < frame.maxY - epsilon, top > frame.minY + epsilon else { continue }
            guard resultX + halfW > frame.minX, resultX - halfW < frame.maxX else { continue }
            if movingRight {
                resultX = min(resultX, frame.minX - halfW)
            } else {
                resultX = max(resultX, frame.maxX + halfW)
            }
        }
        return resultX
    }
}
