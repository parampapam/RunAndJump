//
//  LevelBuilder.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import SpriteKit

/// Создаёт игровые объекты по декларативному описанию уровня.
@MainActor
enum LevelBuilder {

    static func makeEnemy(from descriptor: EnemyDescriptor) -> Enemy {
        let movement: EnemyMovement
        switch descriptor.behavior {
        case .stationary:
            movement = StationaryMovement()
        case .patrolling(let leftX, let rightX, let speed):
            movement = PatrollingMovement(leftX: leftX, rightX: rightX, speed: speed)
        }

        let enemy = Enemy(movement: movement)
        enemy.position = descriptor.position
        return enemy
    }

    static func makePickup(from descriptor: PickupDescriptor) -> Pickup {
        let kind: PickupKind
        switch descriptor.kind {
        case .health:
            kind = .health
        case .bonus(let points):
            kind = .bonus(points: points)
        }

        let pickup = Pickup(kind: kind)
        pickup.position = descriptor.position
        return pickup
    }

    static func makePortal(at position: CGPoint) -> Portal {
        let portal = Portal()
        portal.position = position
        return portal
    }

    static func makePlatform(from descriptor: PlatformDescriptor) -> Platform {
        let platform = Platform(size: descriptor.size)
        platform.position = descriptor.position
        return platform
    }

    static func makeMovingPlatform(from descriptor: MovingPlatformDescriptor) -> MovingPlatform {
        MovingPlatform(descriptor: descriptor)
    }

    static func makeLadder(from descriptor: LadderDescriptor) -> Ladder {
        let ladder = Ladder(size: descriptor.size)
        ladder.position = descriptor.position
        return ladder
    }
}
