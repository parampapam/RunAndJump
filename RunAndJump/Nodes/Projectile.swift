//
//  Projectile.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 27.07.2026.
//

import SpriteKit

/// Снаряд стреляющего врага. Летит горизонтально с постоянной скоростью и
/// гаснет, когда попал в игрока, врезался в геометрию уровня или выработал
/// свой ресурс полёта (`ProjectileSpawn.lifetime`, считается в модели).
final class Projectile: SKSpriteNode {

    /// Снаряд уже израсходован: во что-то попал и вот-вот исчезнет. За один шаг
    /// симуляции контакт может прийти дважды (например, от игрока и от
    /// платформы) — второй сцена по этому флагу игнорирует.
    private(set) var isSpent = false

    private static let fadeDuration: TimeInterval = 0.1
    private static let flightKey = "projectileFlight"

    init(spawn: ProjectileSpawn, texture: SKTexture) {
        super.init(texture: texture, color: .clear, size: Grid.size(ObjectSize.projectile))

        position = spawn.position

        // Тело динамическое, но без гравитации и без коллизий. Динамическое —
        // потому что два статических тела контакта не порождают, а снаряду
        // нужны контакты с землёй, платформами и стенами. Коллизии сняты,
        // чтобы солвер не «отбивал» снаряд: его останавливает сцена, не физика.
        let body = SKPhysicsBody(circleOfRadius: ObjectSize.projectileHitboxRadius * WorldMetrics.tileSize)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        // Дефолтное затухание съедало бы скорость — полёт должен быть ровным.
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.projectile
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
            | PhysicsCategory.ground
            | PhysicsCategory.platform
            | PhysicsCategory.wall
        physicsBody = body

        // Скорость задаём действием, а не прямо в init: действия выполняются,
        // когда узел уже в сцене, — до этого мира физики у тела ещё нет и
        // присвоенная скорость может потеряться.
        run(.sequence([
            .run { [weak self] in self?.physicsBody?.velocity = spawn.velocity },
            .wait(forDuration: spawn.lifetime),
            .run { [weak self] in self?.hit() }
        ]), withKey: Self.flightKey)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Снаряд израсходован: гаснет и покидает сцену.
    func hit() {
        guard !isSpent else { return }
        isSpent = true

        // Тело снимаем отложенно: `hit()` вызывается из обработчика контакта,
        // то есть посреди шага симуляции, — менять физику в этот момент нельзя.
        // Опасность снята раньше: контакт с израсходованным снарядом сцена
        // игнорирует по `isSpent`.
        run(.sequence([
            .run { [weak self] in self?.physicsBody = nil },
            .fadeOut(withDuration: Self.fadeDuration),
            .removeFromParent()
        ]))
    }
}
