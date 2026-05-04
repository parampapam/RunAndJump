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
    private let jumpImpulse: CGFloat = 120

    // Текущее направление движения по горизонтали: -1, 0 или 1.
    private var horizontalDirection: CGFloat = 0

    // Признак, что персонаж касается земли. Обновляется снаружи (из GameScene).
    var isOnGround: Bool = false

    init() {
        let size = CGSize(width: 50, height: 50)
        let texture: SKTexture? = nil
        super.init(texture: texture, color: .red, size: size)

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.allowsRotation = false
        // Чуть-чуть трения, чтобы при остановке не было скольжения.
        body.friction = 0.2
        // Никакой упругости — приземляться, а не отскакивать.
        body.restitution = 0
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
        guard isOnGround else { return }
        physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))
        isOnGround = false
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
