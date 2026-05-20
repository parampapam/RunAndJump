//
//  Portal.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import SpriteKit

final class Portal: LevelObject {

    init(size: CGSize = CGSize(width: 32, height: 64)) {
        super.init(size: size, color: .purple)

        physicsBody?.categoryBitMask = PhysicsCategory.portal
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.player
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
