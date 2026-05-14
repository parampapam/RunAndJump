//
//  PatrollingMovement.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 14.05.2026.
//

import SpriteKit

/// Враг ходит между двумя X-координатами с заданной скоростью.
final class PatrollingMovement: EnemyMovement {

    let leftX: CGFloat
    let rightX: CGFloat
    let speed: CGFloat

    private var direction: CGFloat = 1 // 1 = вправо, -1 = влево

    init(leftX: CGFloat, rightX: CGFloat, speed: CGFloat) {
        self.leftX = leftX
        self.rightX = rightX
        self.speed = speed
    }

    private var lastUpdateTime: TimeInterval?

    func update(node: SKNode, at time: TimeInterval) {
        defer { lastUpdateTime = time }

        guard let last = lastUpdateTime else { return }
        let delta = time - last

        var newX = node.position.x + direction * speed * CGFloat(delta)

        // Достигли границы — разворачиваемся.
        if newX > rightX {
            newX = rightX
            direction = -1
        } else if newX < leftX {
            newX = leftX
            direction = 1
        }

        node.position.x = newX
    }
}
