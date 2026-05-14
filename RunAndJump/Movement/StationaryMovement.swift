//
//  StationaryMovement.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 14.05.2026.
//

import SpriteKit

/// Враг не двигается.
struct StationaryMovement: EnemyMovement {
    func update(node: SKNode, at time: TimeInterval) {
        // ничего не делаем
    }
}
