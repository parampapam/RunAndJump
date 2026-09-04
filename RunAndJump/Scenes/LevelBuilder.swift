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

    /// Фон уровня. Единственный узел, который продолжает переводить тайлы в
    /// пункты и после сборки: полосы едут за камерой каждый кадр, поэтому
    /// `Grid` живёт и внутри `Background` (см. его комментарий).
    static func makeBackground(from configuration: LevelConfiguration) -> Background {
        Background(descriptor: configuration.background,
                   levelSizeInTiles: TileSize(width: configuration.levelWidthInTiles,
                                              height: configuration.levelHeightInTiles))
    }

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

    /// Декорация по описанию; `nil` — такой декорации у стиля нет.
    /// Опечатка в идентификаторе не должна стоить игроку уровня, поэтому
    /// неизвестная декорация просто не рисуется (ловит её `LevelValidation`).
    static func makeDecoration(from descriptor: DecorationDescriptor) -> Decoration? {
        // TODO (шаг 3): каталог приходит снаружи вместе с темой.
        guard let entry = GrasslandCatalog.catalog.decorations[descriptor.id] else { return nil }

        let oneTile = TileSize.one
        let sprites = entry.tiles.compactMap { tile -> SKSpriteNode? in
            let frames = tile.frames.map(grasslandAtlas.textureNamed)
            guard let first = frames.first else { return nil }

            let sprite = SKSpriteNode(texture: first, size: Grid.size(oneTile))
            // Центр ячейки относительно нижнего-левого угла декорации.
            sprite.position = Grid.center(
                origin: TileCoordinate(x: CGFloat(tile.column), y: CGFloat(tile.row)),
                size: oneTile
            )
            animate(sprite,
                    frames: frames,
                    frameDuration: entry.frameDuration,
                    randomizePhase: entry.randomizePhase)
            return sprite
        }
        let decoration = Decoration(tiles: sprites, layer: entry.layer)
        decoration.position = Grid.point(descriptor.origin)
        return decoration
    }

    /// Зацикливает кадры плитки. Один кадр — плитка статична, действия не нужно.
    ///
    /// Фаза сдвигает **начало** цикла, а не его темп: два факела рядом идут с
    /// одной скоростью, но в разных местах петли, и потому не мигают в унисон.
    /// Плитки одной декорации фазу не получают по отдельности — длительность
    /// кадра одна на запись именно затем, чтобы костёр 1×2 шёл в такт.
    private static func animate(_ sprite: SKSpriteNode,
                                frames: [SKTexture],
                                frameDuration: TimeInterval,
                                randomizePhase: Bool) {
        guard frames.count > 1 else { return }

        // resize/restore = false: размер плитки задан сеткой, а не кадром.
        let loop = SKAction.repeatForever(
            .animate(with: frames, timePerFrame: frameDuration, resize: false, restore: false)
        )
        guard randomizePhase else {
            sprite.run(loop)
            return
        }

        let period = frameDuration * Double(frames.count)
        sprite.run(.sequence([.wait(forDuration: .random(in: 0..<period)), loop]))
    }

    static func makeEnemy(from descriptor: EnemyDescriptor, index: Int) -> Enemy {
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

        let enemy = Enemy(kind: descriptor.kind, index: index, movement: movement)
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

    static func makePickup(from descriptor: PickupDescriptor, index: Int) -> Pickup {
        let kind: PickupKind
        switch descriptor.kind {
        case .health:
            kind = .health
        case .coin(let tier):
            kind = .coin(tier)
        }

        let pickup = Pickup(kind: kind, index: index)
        pickup.position = Grid.center(origin: descriptor.origin, size: ObjectSize.pickup)
        return pickup
    }

    /// Флаг точки восстановления. Состояние (поднят / опущен) считает модель по
    /// активной точке — билдер только ставит узел на сетку.
    static func makeCheckpoint(from descriptor: CheckpointDescriptor,
                               index: Int,
                               state: CheckpointState) -> Checkpoint {
        let checkpoint = Checkpoint(index: index, state: state)
        checkpoint.position = Grid.center(origin: descriptor.origin, size: ObjectSize.checkpoint)
        checkpoint.zPosition = ZPosition.checkpoint
        return checkpoint
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
            stops: descriptor.stops
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
