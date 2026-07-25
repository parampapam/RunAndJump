//
//  Pickup.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 11.05.2026.
//

import SpriteKit

final class Pickup: LevelObject {

    let kind: PickupKind

    /// Атлас с кадрами наград (монеты, сердце).
    private let atlas = SKTextureAtlas(named: "Pickups")

    private static let animationKey = "pickupAnimation"

    init(kind: PickupKind, size: CGSize = Grid.size(ObjectSize.pickup)) {
        self.kind = kind
        // Хитбокс — по видимой части спрайта, а не по прозрачным полям кадра.
        super.init(size: size, color: .clear, bodySize: Grid.size(ObjectSize.pickupHitbox))

        physicsBody?.categoryBitMask = PhysicsCategory.pickup
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.player

        let frames = AnimationFrames.Pickup.frames(for: kind).map { atlas.textureNamed($0) }
        guard let first = frames.first else { return }
        // Первый кадр ставим сразу, чтобы спрайт был виден до старта действия.
        texture = first

        guard frames.count > 1 else { return }
        // resize/restore = false: размер узла фиксирован (физика от него не зависит).
        let animate = SKAction.animate(
            with: frames,
            timePerFrame: AnimationDuration.Pickup.timePerFrame(for: kind),
            resize: false,
            restore: false
        )
        run(.repeatForever(animate), withKey: Self.animationKey)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
