//
//  Ladder.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 23.05.2026.
//

import SpriteKit

final class Ladder: SKNode {

    init(descriptor: LadderDescriptor) {
        super.init()

        setupPhysics(size: descriptor.size)
        setupVisual(size: descriptor.size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics(size: CGSize) {
        let bodySize = CGSize(width: size.width * 0.5, height: size.height)
        let body = SKPhysicsBody(rectangleOf: bodySize)
        body.isDynamic = false
        body.affectedByGravity = false
        // Сенсор: без столкновений, только контактные события с игроком.
        body.collisionBitMask = PhysicsCategory.none
        body.categoryBitMask = PhysicsCategory.ladder
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    private func setupVisual(size: CGSize) {
        let railWidth: CGFloat = 8
        let rungHeight: CGFloat = 4
        let rungSpacing: CGFloat = 24
        let ladderColor = SKColor.gray
        let railAlpha: CGFloat = 0.5

        let leftRail = SKSpriteNode(color: ladderColor, size: CGSize(width: railWidth, height: size.height))
        leftRail.position = CGPoint(x: -size.width / 2 + railWidth / 2, y: 0)
        leftRail.alpha = railAlpha
        addChild(leftRail)

        let rightRail = SKSpriteNode(color: ladderColor, size: CGSize(width: railWidth, height: size.height))
        rightRail.position = CGPoint(x: size.width / 2 - railWidth / 2, y: 0)
        rightRail.alpha = railAlpha
        addChild(rightRail)

        let rungWidth = size.width - railWidth * 2
        var rungY = -size.height / 2 + rungSpacing
        while rungY < size.height / 2 {
            let rung = SKSpriteNode(color: ladderColor, size: CGSize(width: rungWidth, height: rungHeight))
            rung.position = CGPoint(x: 0, y: rungY)
            rung.alpha = railAlpha
            addChild(rung)
            rungY += rungSpacing
        }
    }
}
