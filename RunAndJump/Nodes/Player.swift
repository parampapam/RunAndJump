//
//  Player.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

final class Player: SKSpriteNode {

    // Скорость горизонтального движения в точках в секунду.
    private let movementSpeed: CGFloat = 250

    // Сила импульса прыжка.
    private let jumpImpulse: CGFloat = 50

    // Текущее направление движения по горизонтали: -1, 0 или 1.
    private var horizontalDirection: CGFloat = 0

    init() {
        let size = CGSize(width: 32, height: 32)
        let texture: SKTexture? = nil
        super.init(texture: texture, color: .red, size: size)

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.allowsRotation = false
        // Чуть-чуть трения, чтобы при остановке не было скольжения.
        body.friction = 0.2
        // Никакой упругости — приземляться, а не отскакивать.
        body.restitution = 0

        body.categoryBitMask = PhysicsCategory.player
        // Сталкиваемся с землёй и платформами (отскакиваем от них).
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform
        // Уведомления получаем о земле, платформах, врагах, наградах, портале.
        body.contactTestBitMask = PhysicsCategory.ground
            | PhysicsCategory.platform
            | PhysicsCategory.enemy
            | PhysicsCategory.pickup
            | PhysicsCategory.portal

        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Команды (вызываются из GameScene)

    func startMovingLeft() {
        horizontalDirection = -1
    }

    func startMovingRight() {
        horizontalDirection = 1
    }

    func stopMoving() {
        horizontalDirection = 0
    }

    func jump() {
        physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))
    }

    // MARK: - Игровой цикл

    /// Вызывается из GameScene.update каждый кадр.
    func update() {
        guard let body = physicsBody else { return }
        // Перезаписываем горизонтальную скорость, оставляя вертикальную (гравитация, прыжок).
        body.velocity = CGVector(
            dx: horizontalDirection * movementSpeed,
            dy: body.velocity.dy
        )
    }
}
