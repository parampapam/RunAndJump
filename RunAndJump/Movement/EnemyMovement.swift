//
//  EnemyMovement.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 14.05.2026.
//

import SpriteKit

/// Протокол для разных стилей движения врага.
@MainActor
protocol EnemyMovement {
    func update(node: SKNode, at time: TimeInterval)
}
