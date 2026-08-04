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

    /// Кусок земли: невидимый узел с телом-опорой. Вид земле дают плитки травы
    /// (`makeGroundCover`), узел несёт только физику. Кусков несколько, потому
    /// что под озёрами в земле проёмы — их границы считает `GroundLayout`.
    static func makeGround(span: ClosedRange<CGFloat>, height: CGFloat) -> SKSpriteNode {
        let width = Grid.size(TileSize(width: span.upperBound - span.lowerBound, height: 0)).width
        let ground = SKSpriteNode(color: .clear, size: CGSize(width: width, height: height))
        ground.position = CGPoint(x: Grid.point(TileCoordinate(x: span.lowerBound, y: 0)).x + width / 2,
                                  y: height / 2)

        let body = SKPhysicsBody(rectangleOf: ground.size)
        body.isDynamic = false
        // Без упругости: SpriteKit берёт max(restitution) двух тел, и дефолтные
        // 0.2 у опоры подбрасывали бы стоящего игрока (микро-баунс).
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.ground
        // Земля сама ни с кем не «ищет» контактов — её роль пассивная.
        body.contactTestBitMask = PhysicsCategory.none
        ground.physicsBody = body
        return ground
    }

    /// Дно ямы под озером — опора на `HazardKind.depthInTiles` ниже поверхности
    /// земли. Без неё шагнувший в озеро игрок провалился бы за нижний край
    /// уровня: в земле там проём.
    static func makeHazardFloor(from descriptor: HazardDescriptor,
                                groundHeight: CGFloat) -> SKSpriteNode {
        let depth = Grid.size(TileSize(width: 0, height: HazardKind.depthInTiles)).height
        return makeGround(span: descriptor.rect.xSpan, height: max(0, groundHeight - depth))
    }

    /// Травяное покрытие: ряд тайлов вдоль куска земли. Узлы чисто визуальные —
    /// коллизия на теле куска. Если кусок кончается посреди тайла, последняя
    /// плитка обрезается по ширине, чтобы трава не нависала над ямой.
    static func makeGroundCover(span: ClosedRange<CGFloat>) -> [SKSpriteNode] {
        let grass = grasslandAtlas.textureNamed(TextureName.Ground.grassland)
        var tiles: [SKSpriteNode] = []
        var x = span.lowerBound

        while x < span.upperBound - .ulpOfOne {
            let size = TileSize(width: min(1, span.upperBound - x), height: 1)
            let tile = SKSpriteNode(texture: grass, size: Grid.size(size))
            tile.position = Grid.center(origin: TileCoordinate(x: x, y: 0), size: size)
            tile.zPosition = ZPosition.ground
            tiles.append(tile)
            x += size.width
        }
        return tiles
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

    static func makeHazard(from descriptor: HazardDescriptor) -> Hazard {
        let hazard = Hazard(kind: descriptor.kind, size: Grid.size(descriptor.rect.size))
        hazard.position = Grid.center(of: descriptor.rect)
        return hazard
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
