//
//  Player.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

final class Player: SKSpriteNode {

    private let movementSpeed: CGFloat = 250
    private let jumpImpulse: CGFloat = 50
    private let climbSpeed: CGFloat = 150

    private var horizontalDirection: CGFloat = 0
    private var verticalClimbDirection: CGFloat = 0

    private(set) var isOnLadder: Bool = false
    var hasHorizontalInput: Bool { horizontalDirection != 0 }
    /// Горизонтальная скорость от ввода игрока (pts/s), без учёта платформы.
    var horizontalVelocity: CGFloat { horizontalDirection * movementSpeed }

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
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform | PhysicsCategory.wall
        // Уведомления получаем о земле, платформах, врагах, наградах, портале.
        body.contactTestBitMask = PhysicsCategory.ground
            | PhysicsCategory.platform
            | PhysicsCategory.enemy
            | PhysicsCategory.pickup
            | PhysicsCategory.portal
            | PhysicsCategory.ladder

        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Команды движения

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

    // MARK: - Команды лестницы

    func enterLadder(centerX: CGFloat) {
        guard !isOnLadder else { return }
        isOnLadder = true
        // Встаём строго по центру лестницы, чтобы не свисать с края.
        position.x = centerX
        physicsBody?.affectedByGravity = false
        physicsBody?.velocity = .zero
        // Разрешаем проходить сквозь платформы при подъёме.
        physicsBody?.collisionBitMask &= ~PhysicsCategory.platform
    }

    func exitLadder() {
        guard isOnLadder else { return }
        isOnLadder = false
        verticalClimbDirection = 0
        physicsBody?.affectedByGravity = true
        physicsBody?.collisionBitMask |= PhysicsCategory.platform
    }

    func startClimbingUp() {
        verticalClimbDirection = 1
    }

    func startClimbingDown() {
        verticalClimbDirection = -1
    }

    func stopClimbing() {
        verticalClimbDirection = 0
    }

    // MARK: - Игровой цикл

    func update() {
        guard let body = physicsBody else { return }
        if isOnLadder {
            body.velocity = CGVector(dx: 0, dy: verticalClimbDirection * climbSpeed)
        } else {
            body.velocity = CGVector(
                dx: horizontalDirection * movementSpeed,
                dy: body.velocity.dy
            )
        }
    }
}
