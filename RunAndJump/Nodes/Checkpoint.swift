//
//  Checkpoint.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 08.08.2026.
//

import SpriteKit

/// Флаг точки восстановления. Узел только рисует состояние — решение, какой
/// флаг поднят и где возрождается игрок, принимает модель (`CheckpointRules`).
final class Checkpoint: LevelObject {

    /// Индекс в `LevelConfiguration.checkpoints` — им сцена и модель опознают
    /// точку; сам узел его только носит.
    let index: Int

    private(set) var state: CheckpointState

    /// Атлас с наградами и флагами.
    private let atlas = SKTextureAtlas(named: "Pickups")

    private static let raiseActionKey = "checkpointRaise"

    init(index: Int, state: CheckpointState, size: CGSize = Grid.size(ObjectSize.checkpoint)) {
        self.index = index
        self.state = state
        super.init(size: size, color: .clear)

        physicsBody?.categoryBitMask = PhysicsCategory.checkpoint
        // Флаг — декорация с триггером: сквозь него проходят, он лишь сообщает
        // сцене о касании.
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.player

        texture = atlas.textureNamed(AnimationFrames.Checkpoint.frame(for: state))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Меняет состояние флага. Подъём подчёркиваем коротким «подскоком» —
    /// иначе смена текстуры на бегу почти незаметна.
    func setState(_ newState: CheckpointState) {
        guard newState != state else { return }
        state = newState
        texture = atlas.textureNamed(AnimationFrames.Checkpoint.frame(for: newState))

        guard newState == .raised else { return }
        removeAction(forKey: Self.raiseActionKey)
        setScale(1)
        run(.sequence([
            .scale(to: 1.25, duration: 0.12),
            .scale(to: 1.0, duration: 0.12)
        ]), withKey: Self.raiseActionKey)
    }
}
