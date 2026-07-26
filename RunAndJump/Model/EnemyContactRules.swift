//
//  EnemyContactRules.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 26.07.2026.
//

import CoreGraphics

/// Чем закончилось касание игрока и врага.
enum EnemyContactOutcome: Equatable {
    /// Игрок приземлился врагу на голову — враг повержен, игрок отскакивает.
    case stomp
    /// Обычное касание — урон игроку.
    case damage
}

/// Чистое правило «прыжок сверху убивает». Не зависит от SpriteKit: сцена
/// подставляет геометрию тел, правило решает, кто кого — и покрыто тестами.
enum EnemyContactRules {

    /// Верхняя доля высоты врага, попадание в которую считается прыжком на голову.
    /// Полвысоты — компромисс: за кадр падения подошва успевает уйти ниже макушки,
    /// но боковое столкновение (подошва на уровне ног врага) сюда уже не попадает.
    static let stompZone: CGFloat = 0.5

    /// - Parameters:
    ///   - playerBottom: Y подошвы игрока (низ его тела).
    ///   - playerVelocityY: вертикальная скорость игрока; вверх — положительная.
    ///   - enemyTop: Y макушки врага.
    ///   - enemyHeight: высота врага.
    static func outcome(playerBottom: CGFloat,
                        playerVelocityY: CGFloat,
                        enemyTop: CGFloat,
                        enemyHeight: CGFloat) -> EnemyContactOutcome {
        // Взлетающий игрок бьётся о врага снизу — это всегда урон.
        // Ноль пропускаем: в верхней точке прыжка скорость проходит через него,
        // и касание макушки там честнее засчитать как прыжок сверху.
        guard playerVelocityY <= 0 else { return .damage }

        let stompThreshold = enemyTop - enemyHeight * stompZone
        return playerBottom >= stompThreshold ? .stomp : .damage
    }
}
