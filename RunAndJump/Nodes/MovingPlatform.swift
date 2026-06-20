//
//  MovingPlatform.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.05.2026.
//

import SpriteKit

final class MovingPlatform: SKSpriteNode {

    private var motion: OscillatingMotion
    private var clock = FrameClock()

    init(descriptor: MovingPlatformDescriptor) {
        let size = descriptor.size
        motion = OscillatingMotion(
            startPosition: descriptor.startPosition,
            endPosition: descriptor.endPosition,
            speed: descriptor.speed,
            pauseDuration: descriptor.pauseDuration
        )

        super.init(texture: nil, color: .systemOrange, size: size)

        position = motion.position   // = startPosition

        let body = SKPhysicsBody(
            edgeFrom: CGPoint(x: -size.width / 2, y: size.height / 2),
            to: CGPoint(x: size.width / 2, y: size.height / 2)
        )
        body.isDynamic = false
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.platform
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(at time: TimeInterval) {
        guard let dt = clock.tick(at: time) else { return }
        position = motion.advance(by: dt)
    }
}
