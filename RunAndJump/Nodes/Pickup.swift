//
//  Pickup.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 11.05.2026.
//

import SpriteKit

enum PickupKind {
    case health
    case bonus(points: Int)

    var color: SKColor {
        switch self {
        case .health: return .green
        case .bonus: return .yellow
        }
    }
}

final class Pickup: LevelObject {

    let kind: PickupKind

    init(kind: PickupKind, size: CGSize = CGSize(width: 30, height: 30)) {
        self.kind = kind
        super.init(size: size, color: kind.color)

        physicsBody?.categoryBitMask = PhysicsCategory.pickup
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.player
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
