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

    /// Аналоговый горизонтальный ввод в [-1, 1]. Знак — направление,
    /// модуль — доля максимальной скорости.
    private var horizontalInput: CGFloat = 0

    var hasHorizontalInput: Bool { horizontalInput != 0 }

    /// Горизонтальная скорость от ввода игрока (pts/s), без учёта платформы.
    var horizontalVelocity: CGFloat { horizontalInput * movementSpeed }

    // MARK: - Управление коллизиями

    private let defaultCollisionMask: UInt32 =
        PhysicsCategory.ground | PhysicsCategory.platform | PhysicsCategory.wall

    func enableClimbingMode() {
        // Лезем — проходим сквозь платформы, но всё ещё стоим на земле и стенах
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.wall
    }

    func disableClimbingMode() {
        physicsBody?.collisionBitMask = defaultCollisionMask
    }

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
        body.collisionBitMask = defaultCollisionMask
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

    /// Задаёт аналоговый горизонтальный ввод. -1 — полный ход влево,
    /// +1 — полный ход вправо, 0 — стоп, промежуточные значения — частичная
    /// скорость.
    func setHorizontalInput(_ value: CGFloat) {
        horizontalInput = value
    }

    func jump() {
        physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))
    }

    // MARK: - Визуальная индикация неуязвимости

    private static let blinkActionKey = "invulnerabilityBlink"
    /// Длина одного цикла «погас-зажёгся», секунды.
    private static let blinkCycleDuration: TimeInterval = 0.2

    /// Запускает мерцание на `duration` секунд, затем восстанавливает непрозрачность.
    /// Используется, пока действует неуязвимость.
    func startBlinking(for duration: TimeInterval) {
        let halfCycle = Self.blinkCycleDuration / 2
        let blink = SKAction.sequence([
            .fadeAlpha(to: 0.3, duration: halfCycle),
            .fadeAlpha(to: 1.0, duration: halfCycle)
        ])
        let cycles = max(1, Int((duration / Self.blinkCycleDuration).rounded()))
        let restore = SKAction.run { [weak self] in self?.alpha = 1.0 }
        run(.sequence([.repeat(blink, count: cycles), restore]), withKey: Self.blinkActionKey)
    }

    /// Немедленно прекращает мерцание и делает игрока полностью видимым.
    func stopBlinking() {
        removeAction(forKey: Self.blinkActionKey)
        alpha = 1.0
    }

    // MARK: - Игровой цикл

    func update() {
        guard let body = physicsBody else { return }
        // Перезаписываем горизонтальную скорость, оставляя вертикальную (гравитация, прыжок).
        body.velocity = CGVector(
            dx: horizontalInput * movementSpeed,
            dy: body.velocity.dy
        )
    }
}
