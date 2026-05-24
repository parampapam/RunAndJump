//
//  MovingPlatform.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.05.2026.
//

import SpriteKit

final class MovingPlatform: SKSpriteNode {

    private let startPosition: CGPoint
    private let endPosition: CGPoint
    private let totalDistance: CGFloat
    private let movementSpeed: CGFloat
    private let pauseDuration: TimeInterval

    private var progress: CGFloat = 0       // 0 = startPosition, 1 = endPosition
    private var direction: CGFloat = 1      // 1 = к endPosition, -1 = к startPosition
    private var pauseTimeRemaining: TimeInterval = 0
    private var lastUpdateTime: TimeInterval?

    init(descriptor: MovingPlatformDescriptor) {
        let size = descriptor.size
        startPosition = descriptor.startPosition
        endPosition = descriptor.endPosition
        let dx = endPosition.x - startPosition.x
        let dy = endPosition.y - startPosition.y
        totalDistance = sqrt(dx * dx + dy * dy)
        movementSpeed = descriptor.speed
        pauseDuration = descriptor.pauseDuration

        super.init(texture: nil, color: .systemOrange, size: size)

        position = startPosition

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
        guard let last = lastUpdateTime else { return }
        let dt = time - last

        if pauseTimeRemaining > 0 {
            pauseTimeRemaining -= dt
            return
        }

        guard totalDistance > 0 else { return }

        var newProgress = progress + CGFloat(dt) * movementSpeed / totalDistance * direction

        if newProgress >= 1 {
            newProgress = 1
            direction = -1
            pauseTimeRemaining = pauseDuration
        } else if newProgress <= 0 {
            newProgress = 0
            direction = 1
            pauseTimeRemaining = pauseDuration
        }

        let dx = endPosition.x - startPosition.x
        let dy = endPosition.y - startPosition.y
        position = CGPoint(
            x: startPosition.x + dx * newProgress,
            y: startPosition.y + dy * newProgress
        )
        progress = newProgress
    }
}
