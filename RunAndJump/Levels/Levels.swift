//
//  Levels.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import CoreGraphics

/// Уровни заданы в **тайлах**, привязка — к нижнему-левому углу объекта.
/// Земля занимает нижний ряд (высота 1 тайл), поэтому её верх — на y = 1:
/// объекты «на земле» ставятся с y = 1. Платформы задаются прямоугольником
/// (угол + размер), их «толщина» 0.25 тайла, а y угла = высота_верха − 0.25.
enum Levels {

    static let sceneSize = CGSize(width: 1334, height: 750)
    static let levelWidth: CGFloat = 45
    static let levelHeight: CGFloat = 16
    /// Земля — ровно один тайл высотой, чтобы её верх лёг на линию сетки (y = 1).
    static let groundHeight: CGFloat = WorldMetrics.tileSize

    static let all: [LevelConfiguration] = [level1, level2, level3]

    // MARK: - Level 1

    static let level1 = LevelConfiguration(
        name: "Level 1",
        sceneSize: sceneSize,
        levelWidthInTiles: levelWidth,
        levelHeightInTiles: levelHeight,
        playerStart: TileCoordinate(x: 1, y: 1),
        groundHeight: groundHeight,
        // Вводный уровень: пологие холмы, горы лишь мелькают вдалеке.
        background: BackgroundDescriptor(
            fill: .daySky,
            horizon: BackgroundStrip(segments: [.hills, .fill, .mountains, .fill],
                                     widthInTiles: 8),
            sky: BackgroundStrip(segments: [.clouds], widthInTiles: 12),
            horizonLineInTiles: 5
        ),
        platforms: [
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 5, y: 2.75),
                                              size: TileSize(width: 3, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 13, y: 4.75),
                                              size: TileSize(width: 3, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 24, y: 2.75),
                                              size: TileSize(width: 3, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 32, y: 4.75),
                                              size: TileSize(width: 3, height: 0.25))),
        ],
        movingPlatforms: [
            // Горизонтальный мост над серединой уровня (верх на y = 4).
            MovingPlatformDescriptor(
                size: TileSize(width: 3, height: 0.25),
                start: TileCoordinate(x: 18, y: 3.75),
                end: TileCoordinate(x: 22, y: 3.75),
                speed: 90,
                stops: MotionStop.atEnds(0.6)
            ),
        ],
        // Лестница от земли (y = 1) до первой платформы (верх y = 3).
        ladders: [
            LadderDescriptor(origin: TileCoordinate(x: 4.5, y: 1), height: 2.25),
        ],
        // Озеро на ровном месте: два тайла — перепрыгивается с разбега.
        hazards: [
            HazardDescriptor(kind: .water,
                             rect: TileRect(origin: TileCoordinate(x: 23, y: 0),
                                            size: TileSize(width: 2, height: 1))),
        ],
        enemies: [
            .stationary(.plant, at: TileCoordinate(x: 10, y: 1)),
            .patrolling(.crab, at: TileCoordinate(x: 15, y: 1),
                        leftX: 14, rightX: 18, speed: 100),
            .patrolling(.imp, at: TileCoordinate(x: 28, y: 1),
                        leftX: 26, rightX: 30, speed: 120),
            // Оса висит над землёй: под ней можно пройти, но не перепрыгнуть.
            .stationary(.wasp, at: TileCoordinate(x: 38, y: 2.5)),
        ],
        pickups: [
            PickupDescriptor(origin: TileCoordinate(x: 7, y: 3.25), kind: .health),
            PickupDescriptor(origin: TileCoordinate(x: 9, y: 1.25), kind: .coin(.bronze)),
            PickupDescriptor(origin: TileCoordinate(x: 20, y: 1.25), kind: .coin(.silver)),
            PickupDescriptor(origin: TileCoordinate(x: 30, y: 1.25), kind: .coin(.gold)),
            PickupDescriptor(origin: TileCoordinate(x: 40, y: 1.25), kind: .health),
        ],
        // Точки восстановления: перед растением, за крабом и после беса —
        // каждая закрывает участок, на котором легко погибнуть.
        checkpoints: [
            CheckpointDescriptor(origin: TileCoordinate(x: 8, y: 1)),
            CheckpointDescriptor(origin: TileCoordinate(x: 19, y: 1)),
            CheckpointDescriptor(origin: TileCoordinate(x: 31, y: 1)),
        ],
        // Цветы стоят на земле (нижний край на y = 1), разбросаны по уровню.
        decorations: [
            DecorationDescriptor(kind: .rightArrow, origin: TileCoordinate(x: 3, y: 1)),
            DecorationDescriptor(kind: .yellowFlower, origin: TileCoordinate(x: 7, y: 1)),
            DecorationDescriptor(kind: .darkTree, origin: TileCoordinate(x: 12, y: 1)),
            DecorationDescriptor(kind: .tallLightTree, origin: TileCoordinate(x: 13, y: 1)),
            DecorationDescriptor(kind: .bigDarkBush, origin: TileCoordinate(x: 14, y: 1)),
            DecorationDescriptor(kind: .whiteFlower, origin: TileCoordinate(x: 15, y: 5)),
            DecorationDescriptor(kind: .pinkFlower, origin: TileCoordinate(x: 21, y: 1)),
            DecorationDescriptor(kind: .shortDarkGrass, origin: TileCoordinate(x: 22, y: 1)),
            DecorationDescriptor(kind: .purpleFlower, origin: TileCoordinate(x: 27, y: 1)),
            DecorationDescriptor(kind: .tallLightTree, origin: TileCoordinate(x: 28, y: 1)),
            DecorationDescriptor(kind: .tallDarkGrass, origin: TileCoordinate(x: 29, y: 1)),
            DecorationDescriptor(kind: .yellowFlower, origin: TileCoordinate(x: 34, y: 1)),
            DecorationDescriptor(kind: .whiteFlower, origin: TileCoordinate(x: 41, y: 1)),
        ],
        portal: TileCoordinate(x: 42, y: 1)
    )

    // MARK: - Level 2

    static let level2 = LevelConfiguration(
        name: "Level 2",
        sceneSize: sceneSize,
        levelWidthInTiles: levelWidth,
        levelHeightInTiles: levelHeight,
        playerStart: TileCoordinate(x: 1, y: 1),
        groundHeight: groundHeight,
        // Горный уровень: гряда выше и плотнее, разрывы реже.
        background: BackgroundDescriptor(
            fill: .daySky,
            horizon: BackgroundStrip(segments: [.mountains, .fill, .mountains, .hills],
                                     widthInTiles: 8),
            sky: BackgroundStrip(segments: [.clouds], widthInTiles: 14),
            horizonLineInTiles: 6
        ),
        platforms: [
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 4, y: 2.75),
                                              size: TileSize(width: 3, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 9, y: 4.75),
                                              size: TileSize(width: 3, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 12, y: 6.75),
                                              size: TileSize(width: 2, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 16, y: 2.75),
                                              size: TileSize(width: 3, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 23, y: 3.75),
                                              size: TileSize(width: 3, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 31, y: 4.75),
                                              size: TileSize(width: 3, height: 0.25))),
        ],
        movingPlatforms: [
            // Вертикальный лифт (верх ходит между y = 2 и y = 6).
            MovingPlatformDescriptor(
                size: TileSize(width: 3, height: 0.25),
                start: TileCoordinate(x: 27, y: 1.75),
                end: TileCoordinate(x: 27, y: 5.75),
                speed: 100,
                stops: MotionStop.atEnds(1.0)
            ),
        ],
        ladders: [
            // Земля → платформа на y = 5.
            LadderDescriptor(origin: TileCoordinate(x: 8.5, y: 1), height: 5),
            // Платформа y = 5 → платформа y = 7.
            LadderDescriptor(origin: TileCoordinate(x: 11.5, y: 5), height: 3)
        ],
        // Лава ровно под лифтом: можно перепрыгнуть, а можно переждать наверху.
        hazards: [
            HazardDescriptor(kind: .lava,
                             rect: TileRect(origin: TileCoordinate(x: 28, y: 0),
                                            size: TileSize(width: 2, height: 1))),
        ],
        enemies: [
            .patrolling(.crab, at: TileCoordinate(x: 5, y: 1),
                        leftX: 4, rightX: 8, speed: 120),
            .patrolling(.imp, at: TileCoordinate(x: 11, y: 1),
                        leftX: 10, rightX: 14, speed: 150),
            .stationary(.plant, at: TileCoordinate(x: 18, y: 1)),
            .patrolling(.sniper, at: TileCoordinate(x: 33, y: 1),
                        leftX: 32, rightX: 36, speed: 160),
            .patrolling(.crab, at: TileCoordinate(x: 39, y: 1),
                        leftX: 38, rightX: 41, speed: 180),
        ],
        pickups: [
            PickupDescriptor(origin: TileCoordinate(x: 7, y: 1.25), kind: .coin(.silver)),
            PickupDescriptor(origin: TileCoordinate(x: 15, y: 1.25), kind: .coin(.silver)),
            PickupDescriptor(origin: TileCoordinate(x: 20, y: 1.25), kind: .health),
            PickupDescriptor(origin: TileCoordinate(x: 30, y: 1.25), kind: .coin(.gold)),
            PickupDescriptor(origin: TileCoordinate(x: 40, y: 1.25), kind: .health),
        ],
        // Точки восстановления: после беса и перед лифтом с лавой — до снайпера.
        checkpoints: [
            CheckpointDescriptor(origin: TileCoordinate(x: 21, y: 1)),
            CheckpointDescriptor(origin: TileCoordinate(x: 31, y: 1)),
        ],
        decorations: [
            DecorationDescriptor(kind: .yellowFlower, origin: TileCoordinate(x: 3, y: 1)),
            DecorationDescriptor(kind: .whiteFlower, origin: TileCoordinate(x: 13, y: 1)),
            DecorationDescriptor(kind: .pinkFlower, origin: TileCoordinate(x: 22, y: 1)),
            DecorationDescriptor(kind: .purpleFlower, origin: TileCoordinate(x: 25, y: 1)),
            DecorationDescriptor(kind: .yellowFlower, origin: TileCoordinate(x: 36, y: 1)),
            DecorationDescriptor(kind: .pinkFlower, origin: TileCoordinate(x: 43, y: 1)),
        ],
        portal: TileCoordinate(x: 42, y: 1)
    )

    // MARK: - Level 3

    static let level3 = LevelConfiguration(
        name: "Level 3",
        sceneSize: sceneSize,
        levelWidthInTiles: levelWidth,
        levelHeightInTiles: levelHeight,
        playerStart: TileCoordinate(x: 1, y: 1),
        groundHeight: groundHeight,
        // Открытое место: линия горизонта ниже, гряда реже — больше неба.
        background: BackgroundDescriptor(
            fill: .daySky,
            horizon: BackgroundStrip(segments: [.mountains, .fill, .hills, .fill],
                                     widthInTiles: 8),
            sky: BackgroundStrip(segments: [.clouds], widthInTiles: 10),
            horizonLineInTiles: 4
        ),
        platforms: [
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 4, y: 2.75),
                                              size: TileSize(width: 2, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 9, y: 4.75),
                                              size: TileSize(width: 2, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 14, y: 6.75),
                                              size: TileSize(width: 2, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 19, y: 4.75),
                                              size: TileSize(width: 2, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 24, y: 2.75),
                                              size: TileSize(width: 2, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 31, y: 4.75),
                                              size: TileSize(width: 2, height: 0.25))),
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 36, y: 6.75),
                                              size: TileSize(width: 2, height: 0.25))),
        ],
        movingPlatforms: [
            // Горизонтальная подвижная платформа в начале уровня (верх y = 4).
            MovingPlatformDescriptor(
                size: TileSize(width: 3, height: 0.25),
                start: TileCoordinate(x: 6, y: 3.75),
                end: TileCoordinate(x: 10, y: 3.75),
                speed: 120,
                stops: MotionStop.atEnds(0.5)
            ),
            // Вертикальная подвижная платформа во второй половине (верх y = 2…6).
            MovingPlatformDescriptor(
                size: TileSize(width: 3, height: 0.25),
                start: TileCoordinate(x: 28, y: 1.75),
                end: TileCoordinate(x: 28, y: 5.75),
                speed: 110,
                stops: MotionStop.atEnds(0.8)
            ),
        ],
        // Высокая лестница от земли до платформы на y = 7.
        ladders: [
            LadderDescriptor(origin: TileCoordinate(x: 13.5, y: 1), height: 7)
        ],
        // Лужа под подвижной платформой в начале и озеро лавы в конце уровня.
        hazards: [
            HazardDescriptor(kind: .water,
                             rect: TileRect(origin: TileCoordinate(x: 6, y: 0),
                                            size: TileSize(width: 2, height: 1))),
            HazardDescriptor(kind: .lava,
                             rect: TileRect(origin: TileCoordinate(x: 20, y: 0),
                                            size: TileSize(width: 2, height: 1))),
        ],
        enemies: [
            .stationary(.plant, at: TileCoordinate(x: 5, y: 1)),
            .patrolling(.crab, at: TileCoordinate(x: 9, y: 1),
                        leftX: 8, rightX: 11, speed: 180),
            .patrolling(.imp, at: TileCoordinate(x: 14, y: 1),
                        leftX: 13, rightX: 16, speed: 200),
            .stationary(.wasp, at: TileCoordinate(x: 19, y: 2.5)),
            .patrolling(.sniper, at: TileCoordinate(x: 27, y: 1),
                        leftX: 26, rightX: 30, speed: 210),
            .patrolling(.imp, at: TileCoordinate(x: 34, y: 1),
                        leftX: 33, rightX: 37, speed: 220),
            .stationary(.plant, at: TileCoordinate(x: 40, y: 1)),
        ],
        pickups: [
            // Не над озером (6…8), а перед ним — монета должна лежать на земле.
            PickupDescriptor(origin: TileCoordinate(x: 3.5, y: 1.25), kind: .coin(.silver)),
            PickupDescriptor(origin: TileCoordinate(x: 12, y: 1.25), kind: .coin(.gold)),
            PickupDescriptor(origin: TileCoordinate(x: 17, y: 1.25), kind: .coin(.gold)),
            PickupDescriptor(origin: TileCoordinate(x: 30, y: 1.25), kind: .coin(.gold)),
            PickupDescriptor(origin: TileCoordinate(x: 40, y: 1.25), kind: .health),
        ],
        // Самый длинный уровень — три точки: перед осой, после лавы и после беса.
        checkpoints: [
            CheckpointDescriptor(origin: TileCoordinate(x: 18, y: 1)),
            CheckpointDescriptor(origin: TileCoordinate(x: 25, y: 1)),
            CheckpointDescriptor(origin: TileCoordinate(x: 39, y: 1)),
        ],
        decorations: [
            DecorationDescriptor(kind: .whiteFlower, origin: TileCoordinate(x: 2, y: 1)),
            DecorationDescriptor(kind: .purpleFlower, origin: TileCoordinate(x: 11, y: 1)),
            DecorationDescriptor(kind: .pinkFlower, origin: TileCoordinate(x: 16, y: 1)),
            DecorationDescriptor(kind: .yellowFlower, origin: TileCoordinate(x: 23, y: 1)),
            DecorationDescriptor(kind: .whiteFlower, origin: TileCoordinate(x: 32, y: 1)),
            DecorationDescriptor(kind: .purpleFlower, origin: TileCoordinate(x: 38, y: 1)),
            DecorationDescriptor(kind: .pinkFlower, origin: TileCoordinate(x: 43, y: 1)),
        ],
        portal: TileCoordinate(x: 42, y: 1)
    )
}
