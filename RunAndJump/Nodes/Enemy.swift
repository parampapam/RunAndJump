//
//  Enemy.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 11.05.2026.
//

import SpriteKit

final class Enemy: LevelObject {

    private let movement: EnemyMovement

    init(size: CGSize = CGSize(width: 40, height: 40), movement: EnemyMovement = StationaryMovement()) {
        self.movement = movement
        super.init(size: size, color: .black)

        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.player
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(at time: TimeInterval) {
        movement.update(node: self, at: time)
    }
}
