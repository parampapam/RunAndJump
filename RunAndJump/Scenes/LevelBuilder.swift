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
///
/// Структура с темой, а не `enum` со статическими атласами: чем нарисован
/// ландшафт, билдер получает снаружи (`LevelTextures`), поэтому два уровня в
/// разных стилях собираются одним и тем же кодом.
///
/// Тема нужна не всем: игрок, враги, награды и снаряды стиля не имеют — их
/// атласы общие на всю игру, и это осознанная граница.
@MainActor
struct LevelBuilder {

    /// Чем нарисован ландшафт, фон и декорации этого уровня.
    let textures: LevelTextures

    /// Атлас врагов — из него же берётся спрайт снаряда. Статический: у врагов
    /// стиля нет, и подменять его снаружи нечему.
    private static let enemiesAtlas = SKTextureAtlas(named: "Enemies")

    /// Фон уровня. Единственный узел, который продолжает переводить тайлы в
    /// пункты и после сборки: полосы едут за камерой каждый кадр, поэтому
    /// `Grid` живёт и внутри `Background` (см. его комментарий).
    func makeBackground(from configuration: LevelConfiguration) -> Background {
        Background(descriptor: configuration.background,
                   levelSizeInTiles: TileSize(width: configuration.levelWidthInTiles,
                                              height: configuration.levelHeightInTiles),
                   textures: textures)
    }

    /// Кусок рельефа: невидимый узел с телом-опорой. Вид земле дают плитки
    /// (`makeTerrainTiles`), узел несёт только физику. Кусков несколько: их
    /// границы склеивает `TerrainLayout`, и склейка не косметическая — на швах
    /// между соседними телами бегущий игрок спотыкается.
    func makeTerrain(_ rect: TileRect) -> SKSpriteNode {
        let size = Grid.size(rect.size)
        let terrain = SKSpriteNode(color: .clear, size: size)
        terrain.position = Grid.center(of: rect)

        // Вырожденный кусок (например, озеро вровень с поверхностью — яма
        // нулевой глубины) остаётся без тела: SKPhysicsBody нулевого размера
        // ведёт себя непредсказуемо.
        guard size.width > 0, size.height > 0 else { return terrain }

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        // Без упругости: SpriteKit берёт max(restitution) двух тел, и дефолтные
        // 0.2 у опоры подбрасывали бы стоящего игрока (микро-баунс).
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.ground
        // Земля сама ни с кем не «ищет» контактов — её роль пассивная.
        body.contactTestBitMask = PhysicsCategory.none
        terrain.physicsBody = body
        return terrain
    }

    /// Дно ямы под озером — опора на `HazardKind.depthInTiles` ниже поверхности
    /// жидкости. Без неё шагнувший в озеро игрок провалился бы за нижний край
    /// уровня: грунт там вырезан.
    ///
    /// Глубина отсчитывается от **верха озера**, а не от какой-либо общей
    /// высоты земли: озеро стоит вровень с окрестной поверхностью, а она у
    /// каждого озера своя.
    func makeHazardFloor(from descriptor: HazardDescriptor) -> SKSpriteNode {
        let surface = descriptor.rect.origin.y + descriptor.rect.size.height
        let top = max(0, surface - HazardKind.depthInTiles)
        return makeTerrain(TileRect(origin: TileCoordinate(x: descriptor.rect.origin.x, y: 0),
                                    size: TileSize(width: descriptor.rect.size.width, height: top)))
    }

    /// Плитки рельефа: по одной на каждую занятую клетку. Узлы чисто
    /// визуальные — коллизия на телах кусков (`makeTerrain`).
    ///
    /// Чем нарисована клетка, решает `TerrainTiling` по занятости соседей, а
    /// каким изображением — каталог стиля. Билдер только ставит спрайт на
    /// сетку и не знает ни про то, ни про другое.
    func makeTerrainTiles(of map: TerrainMap) -> [SKSpriteNode] {
        let size = TileSize.one
        var tiles: [SKSpriteNode] = []

        for y in 0..<map.height {
            for x in 0..<map.width where map.isSolid(x: x, y: y) {
                let part = TerrainTiling.part(x: x, y: y, in: map)
                let tile = SKSpriteNode(texture: textures.terrain(part), size: Grid.size(size))
                tile.position = Grid.center(origin: TileCoordinate(x: CGFloat(x), y: CGFloat(y)),
                                            size: size)
                tile.zPosition = ZPosition.ground
                tiles.append(tile)
            }
        }
        return tiles
    }

    /// Декорация по описанию; `nil` — такой декорации у стиля нет.
    /// Опечатка в идентификаторе не должна стоить игроку уровня, поэтому
    /// неизвестная декорация просто не рисуется (ловит её `LevelValidation`).
    func makeDecoration(from descriptor: DecorationDescriptor) -> Decoration? {
        guard let entry = textures.decoration(descriptor.id) else {
            // Опечатку автор должен увидеть сразу, а игрок — не заметить вовсе.
            assertionFailure("Стиль \(textures.catalog.id.rawValue) не знает декорации \(descriptor.id.rawValue)")
            return nil
        }

        let oneTile = TileSize.one
        let sprites = entry.tiles.compactMap { tile -> SKSpriteNode? in
            let frames = tile.frames.map { textures.texture(named: $0) }
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
    private func animate(_ sprite: SKSpriteNode,
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

    func makeEnemy(from descriptor: EnemyDescriptor, index: Int) -> Enemy {
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
    func makeProjectile(from spawn: ProjectileSpawn) -> Projectile {
        Projectile(spawn: spawn,
                   texture: Self.enemiesAtlas.textureNamed(TextureName.Enemy.sniperProjectile))
    }

    func makePickup(from descriptor: PickupDescriptor, index: Int) -> Pickup {
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
    func makeCheckpoint(from descriptor: CheckpointDescriptor,
                               index: Int,
                               state: CheckpointState) -> Checkpoint {
        let checkpoint = Checkpoint(index: index, state: state)
        checkpoint.position = Grid.center(origin: descriptor.origin, size: ObjectSize.checkpoint)
        checkpoint.zPosition = ZPosition.checkpoint
        return checkpoint
    }

    func makePortal(from origin: TileCoordinate) -> Portal {
        let portal = Portal()
        portal.position = Grid.center(origin: origin, size: ObjectSize.portal)
        return portal
    }

    func makePlatform(from descriptor: PlatformDescriptor) -> Platform {
        let platform = Platform(size: Grid.size(descriptor.rect.size), textures: textures)
        platform.position = Grid.center(of: descriptor.rect)
        return platform
    }

    func makeMovingPlatform(from descriptor: MovingPlatformDescriptor) -> MovingPlatform {
        MovingPlatform(
            size: Grid.size(descriptor.size),
            textures: textures,
            startPosition: Grid.center(origin: descriptor.start, size: descriptor.size),
            endPosition: Grid.center(origin: descriptor.end, size: descriptor.size),
            speed: descriptor.speed,
            stops: descriptor.stops
        )
    }

    func makeHazard(from descriptor: HazardDescriptor) -> Hazard {
        let hazard = Hazard(kind: descriptor.kind, size: Grid.size(descriptor.rect.size))
        hazard.position = Grid.center(of: descriptor.rect)
        return hazard
    }

    func makeLadder(from descriptor: LadderDescriptor) -> Ladder {
        let ladder = Ladder(heightInTiles: descriptor.height, textures: textures)
        // Низ фиксирован в `descriptor.origin`; высота узла может быть чуть
        // больше запрошенной (см. `LadderTiling`), поэтому центр считаем от
        // уже нормализованного `ladder.size`, а не от исходных тайлов —
        // иначе низ лестницы «утонет» в опоре под ней.
        let origin = Grid.point(descriptor.origin)
        ladder.position = CGPoint(x: origin.x + ladder.size.width / 2, y: origin.y + ladder.size.height / 2)
        return ladder
    }
}
