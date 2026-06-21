//
//  LevelBuilder.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import SpriteKit

/// Создаёт игровые объекты по декларативному описанию уровня.
/// Здесь — единственное место, где тайловые координаты (нижний-левый угол)
/// переводятся в пункты и центр узла через `Grid`.
@MainActor
enum LevelBuilder {

    static func makeEnemy(from descriptor: EnemyDescriptor) -> Enemy {
        let tileSize = ObjectSize.enemy
        let movement: EnemyMovement
        switch descriptor.behavior {
        case .stationary:
            movement = StationaryMovement()
        case .patrolling(let leftX, let rightX, let speed):
            // Патруль двигает центр узла, поэтому к X нижнего-левого угла (в пунктах)
            // прибавляем половину ширины врага.
            let halfWidth = Grid.size(tileSize).width / 2
            movement = PatrollingMovement(
                leftX: Grid.point(TileCoordinate(x: leftX, y: 0)).x + halfWidth,
                rightX: Grid.point(TileCoordinate(x: rightX, y: 0)).x + halfWidth,
                speed: speed
            )
        }

        let enemy = Enemy(movement: movement)
        enemy.position = Grid.center(origin: descriptor.origin, size: tileSize)
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
        pickup.position = Grid.center(origin: descriptor.origin, size: ObjectSize.pickup)
        return pickup
    }

    static func makePortal(from origin: TileCoordinate) -> Portal {
        let portal = Portal()
        portal.position = Grid.center(origin: origin, size: ObjectSize.portal)
        return portal
    }

    static func makePlatform(from descriptor: PlatformDescriptor) -> Platform {
        let platform = Platform(size: Grid.size(descriptor.rect.size))
        platform.position = Grid.center(of: descriptor.rect)
        return platform
    }

    static func makeMovingPlatform(from descriptor: MovingPlatformDescriptor) -> MovingPlatform {
        MovingPlatform(
            size: Grid.size(descriptor.size),
            startPosition: Grid.center(origin: descriptor.start, size: descriptor.size),
            endPosition: Grid.center(origin: descriptor.end, size: descriptor.size),
            speed: descriptor.speed,
            pauseDuration: descriptor.pauseDuration
        )
    }

    static func makeLadder(from descriptor: LadderDescriptor) -> Ladder {
        let ladder = Ladder(size: Grid.size(descriptor.rect.size))
        ladder.position = Grid.center(of: descriptor.rect)
        return ladder
    }
}
