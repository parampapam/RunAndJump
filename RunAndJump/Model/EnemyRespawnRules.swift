//
//  EnemyRespawnRules.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 08.08.2026.
//

import Foundation

/// Судьба поверженных врагов при гибели игрока.
///
/// Враг — препятствие, а не награда, поэтому правило обратное наградам:
/// участок, который придётся переигрывать, должен встретить игрока в прежней
/// сложности. Побеждённые после последнего флага враги возвращаются на уровень,
/// а очки за них снимаются — иначе счёт разошёлся бы с уровнем и гибель стала
/// бы способом набивать очки, убивая одного и того же врага. Победы до флага
/// засчитаны окончательно: их флаг и сохранил.
enum EnemyRespawnRules {

    /// Очки, которые нужно снять за врагов, возвращаемых на уровень.
    /// Неизвестные индексы (описание уровня изменилось) просто игнорируются.
    static func refund(for restored: Set<Int>, in enemies: [EnemyDescriptor]) -> Int {
        restored.reduce(0) { total, index in
            guard enemies.indices.contains(index) else { return total }
            return total + enemies[index].kind.defeatPoints
        }
    }
}
