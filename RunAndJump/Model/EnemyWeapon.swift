//
//  EnemyWeapon.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 27.07.2026.
//

import CoreGraphics
import Foundation

/// Оружие врага — все параметры стрельбы одним значением. Есть не у каждого
/// вида: `EnemyKind.weapon` возвращает nil тем, кто не стреляет, и по этому же
/// признаку сцена понимает, кого вообще спрашивать о выстреле.
///
/// Дальности заданы в тайлах — в той же единице, в которой авторятся уровни;
/// скорость снаряда, как и скорость патруля, — в пунктах/с.
struct EnemyWeapon: Equatable {

    /// Насколько далеко по X враг замечает цель, тайлы.
    let sightRangeInTiles: CGFloat

    /// Допустимая разница по Y между стрелком и целью, тайлы. Снаряд летит
    /// строго горизонтально, поэтому стрелять в того, кто заметно выше или
    /// ниже, бессмысленно — от такого выстрела спасает прыжок на платформу.
    let verticalToleranceInTiles: CGFloat

    /// Сколько враг «целится» после того, как заметил цель, до первого выстрела.
    /// Даёт игроку долю секунды на реакцию — иначе шаг в зону обстрела сразу
    /// стоил бы сердца.
    let aimDelay: TimeInterval

    /// Пауза между выстрелами, пока цель остаётся на виду, секунды.
    let cooldown: TimeInterval

    /// Скорость снаряда, пункты/с.
    let projectileSpeed: CGFloat

    /// Дальность полёта снаряда, тайлы. Пролетев её, снаряд гаснет сам —
    /// страховка от узлов, улетающих в бесконечность.
    let projectileRangeInTiles: CGFloat

    // MARK: - Производные величины в пунктах

    var sightRange: CGFloat { sightRangeInTiles * WorldMetrics.tileSize }
    var verticalTolerance: CGFloat { verticalToleranceInTiles * WorldMetrics.tileSize }
    var projectileRange: CGFloat { projectileRangeInTiles * WorldMetrics.tileSize }

    /// Сколько живёт снаряд: дальность, делённая на скорость.
    var projectileLifetime: TimeInterval {
        guard projectileSpeed > 0 else { return 0 }
        return TimeInterval(projectileRange / projectileSpeed)
    }
}
