//
//  Enemy.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 11.05.2026.
//

import SpriteKit

final class Enemy: LevelObject {

    /// Вид врага: от него зависят кадры анимации и темп цикла.
    let kind: EnemyKind

    /// Индекс в `LevelConfiguration.enemies` — им сцена помечает победу, чтобы
    /// после флага враг на уровень не вернулся.
    let index: Int

    private let movement: EnemyMovement

    /// Атлас с кадрами врагов (краб, бес, снайпер, растение, оса).
    private let atlas = SKTextureAtlas(named: "Enemies")

    private static let animationKey = "enemyAnimation"

    /// Текущее направление взгляда (по умолчанию — вправо, как в атласе).
    /// Снаружи нужно стрельбе: снаряд летит туда же, куда смотрит враг.
    private(set) var facing: EnemyFacing = .right

    /// Отсчёт выстрелов. Есть только у видов с оружием (`EnemyKind.weapon`);
    /// у остальных nil — они не стрелки.
    private var shooting: ShootingController?

    /// Умеет ли этот враг стрелять. Сцена по этому признаку отбирает тех,
    /// кого вообще нужно спрашивать о выстреле каждый кадр.
    var canShoot: Bool { shooting != nil }

    /// Повержен ли враг. Такой враг не двигается, не бьёт игрока и вот-вот исчезнет.
    private(set) var isDefeated = false

    /// Сколько поверженный враг лежит на месте до исчезновения, секунды.
    private static let defeatLingerDuration: TimeInterval = 0.35
    private static let defeatFadeDuration: TimeInterval = 0.25
    private static let defeatKey = "enemyDefeat"

    init(kind: EnemyKind,
         index: Int,
         size: CGSize = Grid.size(ObjectSize.enemy),
         movement: EnemyMovement = StationaryMovement()) {
        self.kind = kind
        self.index = index
        self.movement = movement
        self.shooting = kind.weapon.map(ShootingController.init(weapon:))
        super.init(size: size, color: .clear)

        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.player

        playAnimation(for: .alive)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(at time: TimeInterval) {
        guard !isDefeated else { return }

        // Направление берём из фактического сдвига за кадр: так разворот на
        // краю патруля отрабатывает сам, без ведома стратегии движения.
        let previousX = position.x
        movement.update(node: self, at: time)
        updateFacing(dx: position.x - previousX)
    }

    // MARK: - Стрельба

    /// Спрашивает врага, стреляет ли он в этом кадре, и если да — возвращает
    /// описание снаряда. Сам узел снаряда создаёт сцена: иерархией владеет она.
    ///
    /// Решение целиком за чистой моделью (`ShootingController` + `ProjectileRules`);
    /// здесь только подстановка геометрии узла. Повержённый враг и вид без
    /// оружия всегда возвращают nil.
    func updateShooting(at time: TimeInterval, targetPosition: CGPoint) -> ProjectileSpawn? {
        guard !isDefeated, let weapon = kind.weapon else { return nil }
        guard shooting?.update(at: time,
                               shooter: position,
                               facing: facing,
                               target: targetPosition) == true else { return nil }

        return ProjectileRules.spawn(shooterCenter: position,
                                     shooterSize: size,
                                     facing: facing,
                                     weapon: weapon)
    }

    // MARK: - Поражение

    /// Игрок прыгнул врагу на голову: враг замирает в кадре поражения,
    /// перестаёт быть опасным и исчезает со сцены.
    func defeat() {
        guard !isDefeated else { return }
        isDefeated = true

        // Тело убираем не сразу: `defeat()` вызывается из обработчика контакта,
        // то есть посреди шага симуляции, — менять физику в этот момент нельзя.
        // Действие выполнится уже после шага. Опасность снята раньше: контакт с
        // поверженным врагом сцена игнорирует по `isDefeated`.
        run(.sequence([
            .run { [weak self] in
                self?.physicsBody = nil
                self?.playAnimation(for: .defeated)
            },
            .wait(forDuration: Self.defeatLingerDuration),
            .fadeOut(withDuration: Self.defeatFadeDuration),
            .removeFromParent()
        ]), withKey: Self.defeatKey)
    }

    // MARK: - Анимация

    private func updateFacing(dx: CGFloat) {
        let newFacing = EnemyAnimation.facing(dx: dx, current: facing)
        guard newFacing != facing else { return }
        facing = newFacing
        // Кадры нарисованы вправо: для движения влево зеркалим узел по X.
        xScale = facing == .right ? 1 : -1
    }

    private func playAnimation(for state: EnemyAnimationState) {
        let frames = AnimationFrames.Enemy.frames(for: kind, state: state)
            .map { atlas.textureNamed($0) }
        guard let first = frames.first else { return }

        removeAction(forKey: Self.animationKey)
        // Первый кадр ставим сразу, чтобы спрайт был виден до старта действия.
        texture = first

        guard frames.count > 1 else { return }
        // resize/restore = false: размер узла фиксирован (физика от него не зависит).
        let animate = SKAction.animate(
            with: frames,
            timePerFrame: AnimationDuration.Enemy.timePerFrame(for: kind),
            resize: false,
            restore: false
        )
        run(.repeatForever(animate), withKey: Self.animationKey)
    }
}
