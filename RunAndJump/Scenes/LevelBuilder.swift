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

    /// Атлас травяных тайлов и декораций (земля, цветы и пр.).
    private static let grasslandAtlas = SKTextureAtlas(named: "Grassland")

    /// Атлас врагов — из него же берётся спрайт снаряда.
    private static let enemiesAtlas = SKTextureAtlas(named: "Enemies")

    /// Травяное покрытие земли: один ряд тайлов по всей ширине уровня.
    /// Узлы чисто визуальные — коллизия остаётся на едином физическом теле
    /// земли (создаётся в сцене).
    static func makeGroundCover(widthInTiles: Int) -> [SKSpriteNode] {
        let grass = grasslandAtlas.textureNamed(TextureName.Ground.grassland)
        let tileSize = TileSize.one
        return (0..<max(0, widthInTiles)).map { column in
            let tile = SKSpriteNode(texture: grass, size: Grid.size(tileSize))
            tile.position = Grid.center(origin: TileCoordinate(x: CGFloat(column), y: 0),
                                        size: tileSize)
            tile.zPosition = ZPosition.ground
            return tile
        }
    }

    static func makeDecoration(from descriptor: DecorationDescriptor) -> Decoration {
        let oneTile = TileSize.one
        let sprites = DecorationTiles.tiles(for: descriptor.kind).map { tile -> SKSpriteNode in
            let sprite = SKSpriteNode(texture: grasslandAtlas.textureNamed(tile.textureName),
                                      size: Grid.size(oneTile))
            // Центр ячейки относительно нижнего-левого угла декорации.
            sprite.position = Grid.center(
                origin: TileCoordinate(x: CGFloat(tile.column), y: CGFloat(tile.row)),
                size: oneTile
            )
            return sprite
        }
        let decoration = Decoration(tiles: sprites)
        decoration.position = Grid.point(descriptor.origin)
        return decoration
    }

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

        let enemy = Enemy(kind: descriptor.kind, movement: movement)
        enemy.position = Grid.center(origin: descriptor.origin, size: tileSize)
        return enemy
    }

    /// Снаряд по описанию выстрела. В отличие от прочих объектов, он рождается
    /// не из конфигурации уровня, а по ходу игры — позиция уже в пунктах,
    /// её посчитала модель (`ProjectileRules`).
    static func makeProjectile(from spawn: ProjectileSpawn) -> Projectile {
        Projectile(spawn: spawn,
                   texture: enemiesAtlas.textureNamed(TextureName.Enemy.sniperProjectile))
    }

    static func makePickup(from descriptor: PickupDescriptor) -> Pickup {
        let kind: PickupKind
        switch descriptor.kind {
        case .health:
            kind = .health
        case .coin(let tier):
            kind = .coin(tier)
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
        let ladder = Ladder(heightInTiles: descriptor.height)
        // Низ фиксирован в `descriptor.origin`; высота узла может быть чуть
        // больше запрошенной (см. `LadderTiling`), поэтому центр считаем от
        // уже нормализованного `ladder.size`, а не от исходных тайлов —
        // иначе низ лестницы «утонет» в опоре под ней.
        let origin = Grid.point(descriptor.origin)
        ladder.position = CGPoint(x: origin.x + ladder.size.width / 2, y: origin.y + ladder.size.height / 2)
        return ladder
    }
}
