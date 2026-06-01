//
//  OscillatingMotion.swift
//  RunAndJump
//
//  Created by Roman Pospelov on [сегодня].
//

import Foundation
import CoreGraphics

/// Движение между двумя точками туда-обратно с паузами в концах.
/// Чистая геометрия и тайминг — никакого SpriteKit. Единая реализация хода
/// «туда-обратно»: её использует и узел `MovingPlatform`, и патрулирующий враг
/// (`PatrollingMovement`) как частный случай — горизонтальный путь без пауз.
/// Вызывающая сторона переводит абсолютное время кадра в `dt` и применяет
/// полученную позицию.
struct OscillatingMotion: Equatable {

    // MARK: Конфигурация

    let startPosition: CGPoint
    let endPosition: CGPoint
    /// Скорость движения в точках в секунду.
    let speed: CGFloat
    /// Задержка в крайних точках, секунды.
    let pauseDuration: TimeInterval

    /// Полная длина пути между концами — определяет, как быстро растёт прогресс.
    private let totalDistance: CGFloat

    // MARK: Состояние

    /// 0 = startPosition, 1 = endPosition.
    private var progress: CGFloat = 0
    /// 1 = к endPosition, -1 = к startPosition.
    private var direction: CGFloat = 1
    /// Сколько ещё секунд стоять в крайней точке.
    private var pauseTimeRemaining: TimeInterval = 0

    /// - Parameter initialProgress: где начать на отрезке (0 = start, 1 = end),
    ///   клампится в [0, 1]. По умолчанию 0. Полезно для патрулирующего врага,
    ///   которого ставят в середине отрезка, а не на его краю.
    init(
        startPosition: CGPoint,
        endPosition: CGPoint,
        speed: CGFloat,
        pauseDuration: TimeInterval,
        initialProgress: CGFloat = 0
    ) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.speed = speed
        self.pauseDuration = pauseDuration

        let dx = endPosition.x - startPosition.x
        let dy = endPosition.y - startPosition.y
        self.totalDistance = (dx * dx + dy * dy).squareRoot()
        self.progress = min(max(initialProgress, 0), 1)
    }

    /// Текущая позиция платформы — линейная интерполяция концов по прогрессу.
    var position: CGPoint {
        CGPoint(
            x: startPosition.x + (endPosition.x - startPosition.x) * progress,
            y: startPosition.y + (endPosition.y - startPosition.y) * progress
        )
    }

    /// Продвигает движение на `dt` секунд и возвращает новую позицию.
    /// В крайних точках выдерживает паузу, затем разворачивается.
    mutating func advance(by dt: TimeInterval) -> CGPoint {
        if pauseTimeRemaining > 0 {
            pauseTimeRemaining -= dt
            return position
        }

        guard totalDistance > 0 else { return position }

        var newProgress = progress + CGFloat(dt) * speed / totalDistance * direction

        if newProgress >= 1 {
            newProgress = 1
            direction = -1
            pauseTimeRemaining = pauseDuration
        } else if newProgress <= 0 {
            newProgress = 0
            direction = 1
            pauseTimeRemaining = pauseDuration
        }

        progress = newProgress
        return position
    }
}
