//
//  Ladder.swift
//  RunAndJump
//
//  Created by Roman Pospelov on [сегодня].
//

import SpriteKit

final class Ladder: SKSpriteNode {

    init(size: CGSize) {
        let texture: SKTexture? = nil
        // Полупрозрачный коричневый, чтобы визуально отличать от земли.
        // Заменишь на текстуру, когда дойдёшь до арта.
        super.init(texture: texture, color: .brown, size: size)
        alpha = 0.6

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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
