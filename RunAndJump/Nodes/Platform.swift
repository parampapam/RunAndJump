//
//  Platform.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 18.05.2026.
//

import SpriteKit

final class Platform: SKSpriteNode {

    init(size: CGSize) {
        super.init(texture: nil, color: .darkGray, size: size)

        // Только верхнее ребро — это даёт одностороннюю коллизию:
        // приземлиться сверху можно, прыгнуть снизу сквозь — тоже можно.
        let body = SKPhysicsBody(
            edgeFrom: CGPoint(x: -size.width / 2, y: size.height / 2),
            to: CGPoint(x: size.width / 2, y: size.height / 2)
        )
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.platform
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
