//
//  ShootingController.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 27.07.2026.
//

import CoreGraphics
import Foundation

/// Чистое правило видимости: замечает ли стрелок цель прямо сейчас.
/// Не зависит от SpriteKit — сцена подставляет геометрию, правило решает.
enum ShootingRules {

    /// Цель на прицеле, если она **впереди** по направлению взгляда, ближе
    /// `sightRange` по X и не дальше `verticalTolerance` по Y.
    static func canSee(shooter: CGPoint,
                       facing: EnemyFacing,
                       target: CGPoint,
                       weapon: EnemyWeapon) -> Bool {
        let dx = target.x - shooter.x
        // Стреляют только вперёд: снаряд летит туда же, куда смотрит враг.
        let facesTarget = facing == .right ? dx > 0 : dx < 0
        guard facesTarget, abs(dx) <= weapon.sightRange else { return false }
        return abs(target.y - shooter.y) <= weapon.verticalTolerance
    }
}

/// Отсчитывает, в какой момент стрелок делает выстрел. Чистое состояние,
/// без SpriteKit и без узлов — покрыто юнит-тестами.
///
/// Порядок такой: пока цель не видна, таймеры сброшены. Как только цель попала
/// в зону обстрела, враг `aimDelay` секунд целится, затем стреляет и дальше
/// повторяет выстрел каждые `cooldown`, пока цель остаётся на виду. Потеря цели
/// сбрасывает прицеливание — вернувшийся в зону игрок снова получает фору.
struct ShootingController {

    let weapon: EnemyWeapon

    /// Момент, когда цель попала в зону обстрела; nil — цели нет.
    private var acquiredAt: TimeInterval?

    /// Момент последнего выстрела по текущей цели; nil — ещё не стреляли.
    private var lastShotAt: TimeInterval?

    init(weapon: EnemyWeapon) {
        self.weapon = weapon
    }

    /// Вызывается каждый кадр. Возвращает `true` ровно в тот кадр, когда нужно
    /// создать снаряд, — сам снаряд делает сцена.
    mutating func update(at time: TimeInterval,
                         shooter: CGPoint,
                         facing: EnemyFacing,
                         target: CGPoint) -> Bool {
        guard ShootingRules.canSee(shooter: shooter,
                                   facing: facing,
                                   target: target,
                                   weapon: weapon) else {
            acquiredAt = nil
            lastShotAt = nil
            return false
        }

        let acquired = acquiredAt ?? time
        acquiredAt = acquired

        // До первого выстрела ждём прицеливание, дальше — кулдаун.
        let readyAt = lastShotAt.map { $0 + weapon.cooldown } ?? (acquired + weapon.aimDelay)
        guard time >= readyAt else { return false }

        lastShotAt = time
        return true
    }
}
