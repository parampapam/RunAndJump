//
//  HazardKind.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 30.07.2026.
//

import Foundation

/// Вид опасной зоны на земле — озеро воды или лавы.
///
/// Всё, чем виды отличаются друг от друга по механике, собрано здесь: сколько
/// здоровья снимает попадание и как долго зона не может ударить снова, пока
/// игрок из неё не вышел. Новая разновидность препятствия — это новый case
/// плюс его цвета в слое узлов; сцена ничего про виды не знает.
enum HazardKind: CaseIterable, Equatable {

    case water
    case lava

    /// Урон за одно попадание.
    var damage: Int {
        switch self {
        case .water: return 1
        case .lava:  return 2
        }
    }

    /// Пауза до следующего удара, пока игрок остаётся в зоне. Она же — окно
    /// неуязвимости после удара: выбравшись из озера, игрок ещё успевает
    /// отбежать. Лава бьёт вдвое чаще воды и вдвое больнее.
    var damageInterval: TimeInterval {
        switch self {
        case .water: return 2.0
        case .lava:  return 1.0
        }
    }

    /// Игровое событие попадания в зону. Сцена не разбирает виды —
    /// она просто применяет событие (как с наградами и врагами).
    var event: GameEvent {
        .hazardHit(damage: damage)
    }
}
