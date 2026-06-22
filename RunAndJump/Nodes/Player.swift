//
//  Player.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

final class Player: SKSpriteNode {

    private let movementSpeed: CGFloat = 250
    private let jumpImpulse: CGFloat = 150

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
        // Персонаж размером в тайл — единый источник масштаба мира (WorldMetrics).
        let size = CGSize(width: WorldMetrics.tileSize, height: WorldMetrics.tileSize)
        super.init(texture: nil, color: .red, size: size)

        // Стартуем с кадра покоя, чтобы спрайт был виден до первого update.
        texture = animationFrames[.idle]?.first

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

    // MARK: - Анимация

    /// Атлас с кадрами игрока. В атласе все кадры нарисованы «вправо».
    private let atlas = SKTextureAtlas(named: "Player")

    /// Кадры на каждое состояние анимации. Лениво — атлас читается один раз.
    /// idle — один статичный кадр: стоя персонаж не должен «дёргаться».
    private lazy var animationFrames: [PlayerAnimationState: [SKTexture]] = [
        .idle:    ["player_idle_0", "player_idle_1"].map { atlas.textureNamed($0) },
        .running: ["player_walk_0", "player_walk_1"].map { atlas.textureNamed($0) },
        .jumping: ["player_jump"].map { atlas.textureNamed($0) }
    ]

    /// Длительность кадра для каждого состояния, секунды.
    private let frameDurations: [PlayerAnimationState: TimeInterval] = [
        .idle: 2,
        .running: 0.08,
        .jumping: 0.1
    ]

    private static let animationKey = "playerAnimation"

    /// Текущее проигрываемое состояние; nil — анимация ещё не запускалась.
    private var currentAnimationState: PlayerAnimationState?
    /// Текущее направление взгляда (по умолчанию — вправо, как в атласе).
    private var facing: PlayerFacing = .right

    /// Обновляет визуальное состояние: выбор кадров и зеркалирование по направлению.
    /// `isOnGround` берём из `JumpController`, остальное — из текущего ввода.
    func updateAnimation(isOnGround: Bool) {
        let newFacing = PlayerAnimation.facing(horizontalInput: horizontalInput, current: facing)
        if newFacing != facing {
            facing = newFacing
            // Кадры нарисованы вправо: для движения влево зеркалим узел по X.
            xScale = facing == .right ? 1 : -1
        }

        let newState = PlayerAnimation.state(
            isOnGround: isOnGround,
            horizontalInput: horizontalInput
        )
        guard newState != currentAnimationState else { return }
        currentAnimationState = newState
        playAnimation(for: newState)
    }

    private func playAnimation(for state: PlayerAnimationState) {
        guard let frames = animationFrames[state], !frames.isEmpty else { return }
        removeAction(forKey: Self.animationKey)
        speed = 1

        // Одиночный кадр — просто ставим текстуру, без бесконечного действия.
        guard frames.count > 1 else {
            texture = frames[0]
            return
        }

        // resize/restore = false: размер узла фиксирован (физика от него не зависит).
        let animate = SKAction.animate(
            with: frames,
            timePerFrame: frameDurations[state] ?? 0.15,
//            timePerFrame: frameDuration(for: state, horizontalInput: horizontalInput),
            resize: false,
            restore: false
        )
        run(.repeatForever(animate), withKey: Self.animationKey)
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

        if currentAnimationState == .running {
            speed = horizontalInput.magnitude
        } else {
            speed = 1
        }
    }
}
