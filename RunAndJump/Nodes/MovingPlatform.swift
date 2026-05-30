//
//  MovingPlatform.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.05.2026.
//

import SpriteKit

final class MovingPlatform: SKSpriteNode {

    private var motion: MovingPlatformMotion
    private var lastUpdateTime: TimeInterval?

    init(descriptor: MovingPlatformDescriptor) {
        let size = descriptor.size
        motion = MovingPlatformMotion(
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
        body.categoryBitMask = PhysicsCategory.platform
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(at time: TimeInterval) {
        defer { lastUpdateTime = time }
        // Первый кадр только фиксирует время — dt появляется со следующего.
        guard let last = lastUpdateTime else { return }
        position = motion.advance(by: time - last)
    }
}
