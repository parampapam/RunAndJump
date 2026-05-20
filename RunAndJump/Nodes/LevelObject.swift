//
//  LevelObject.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 11.05.2026.
//

import SpriteKit

/// Базовый класс для всех игровых объектов уровня (враги, награды, портал).
/// Содержит общую визуальную и физическую настройку.
class LevelObject: SKSpriteNode {

    init(size: CGSize, color: SKColor) {
        super.init(texture: nil, color: color, size: size)

        /// Все объекты статичные, включая патрулирующего врага. На него не действует гравитация
        /// и физика. Управление его движением через метод update, иначе враги будут падать с
        /// платформы и скользить по физике.
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.allowsRotation = false
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Вызывается каждый кадр сценой. По умолчанию ничего не делает –
    /// подклассы переопределяют для своей логики (например, патрулирования).
    func update(at time: TimeInterval) {
        // override in subclasses
    }
}
