//
//  PatrollingMovement.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 14.05.2026.
//

import SpriteKit

/// Враг ходит между двумя X-координатами с заданной скоростью.
///
/// Тонкий адаптер над чистым `MovingPlatformMotion`: логика хода «туда-обратно
/// между двумя точками» переиспользуется и платформой, и врагом. Здесь остаётся
/// лишь перевод абсолютного времени кадра в `dt` и применение позиции к узлу —
/// ровно то же, что делает узел `MovingPlatform`.
final class PatrollingMovement: EnemyMovement {

    let leftX: CGFloat
    let rightX: CGFloat
    let speed: CGFloat

    /// Создаётся лениво на первом кадре: Y и стартовый X берём из позиции узла,
    /// которую выставил `LevelBuilder`.
    private var motion: OscillatingMotion?
    private var clock = FrameClock()

    init(leftX: CGFloat, rightX: CGFloat, speed: CGFloat) {
        self.leftX = leftX
        self.rightX = rightX
        self.speed = speed
    }

    func update(node: SKNode, at time: TimeInterval) {
        if motion == nil {
            motion = makeMotion(startX: node.position.x, y: node.position.y)
        }

        guard let dt = clock.tick(at: time) else { return }
        node.position = motion!.advance(by: dt)
    }

    /// Горизонтальный патруль leftX↔rightX без пауз. Стартовый прогресс берём из
    /// текущего X врага, чтобы он начинал с места установки, а не прыгал на leftX.
    private func makeMotion(startX: CGFloat, y: CGFloat) -> OscillatingMotion {
        let span = rightX - leftX
        let progress = span > 0 ? (startX - leftX) / span : 0
        return OscillatingMotion(
            startPosition: CGPoint(x: leftX, y: y),
            endPosition: CGPoint(x: rightX, y: y),
            speed: speed,
            stops: [],
            initialProgress: progress
        )
    }
}
