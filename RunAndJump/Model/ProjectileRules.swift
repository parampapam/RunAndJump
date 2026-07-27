//
//  ProjectileRules.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 27.07.2026.
//

import CoreGraphics
import Foundation

/// Снаряд в момент рождения: где появился, куда и как долго летит.
/// Чистые данные — по ним сцена создаёт узел `Projectile`.
struct ProjectileSpawn: Equatable {
    let position: CGPoint
    let velocity: CGVector
    /// Сколько секунд снаряд летит, если ни во что не попал.
    let lifetime: TimeInterval
}

/// Чистая геометрия выстрела: откуда вылетает снаряд и с какой скоростью.
enum ProjectileRules {

    /// Зазор между телом стрелка и снарядом, пункты. Нужен, чтобы снаряд не
    /// рождался «внутри» врага и не выглядел приклеенным к нему.
    static let muzzleGap: CGFloat = 2

    /// Снаряд появляется у переднего края стрелка, на высоте его центра, и
    /// летит горизонтально в ту сторону, куда стрелок смотрит.
    static func spawn(shooterCenter: CGPoint,
                      shooterSize: CGSize,
                      facing: EnemyFacing,
                      weapon: EnemyWeapon) -> ProjectileSpawn {
        let sign: CGFloat = facing == .right ? 1 : -1
        return ProjectileSpawn(
            position: CGPoint(x: shooterCenter.x + sign * (shooterSize.width / 2 + muzzleGap),
                              y: shooterCenter.y),
            velocity: CGVector(dx: sign * weapon.projectileSpeed, dy: 0),
            lifetime: weapon.projectileLifetime
        )
    }
}
