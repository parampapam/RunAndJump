//
//  Ladder.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.05.2026.
//

import SpriteKit

final class Ladder: SKNode {

    init(size: CGSize) {
        super.init()
        setupPhysics(size: size)
        setupVisual(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics(size: CGSize) {
        let body = SKPhysicsBody(rectangleOf: size)
        // Лестница не двигается и не подвержена силам.
        body.isDynamic = false
        body.affectedByGravity = false

        body.categoryBitMask = PhysicsCategory.ladder
        // Ни с чем не сталкиваемся — игрок проходит сквозь.
        body.collisionBitMask = PhysicsCategory.none
        // Уведомление о пересечении с игроком получаем со стороны игрока;
        // здесь можно оставить 0 или продублировать — physics engine
        // зарегистрирует контакт, если хотя бы одна сторона его запросила.
        body.contactTestBitMask = PhysicsCategory.none
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
