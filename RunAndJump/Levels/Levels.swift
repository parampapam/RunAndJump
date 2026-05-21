//
//  Levels.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import CoreGraphics

enum Levels {

    static let sceneSize = CGSize(width: 1334, height: 750)
    static let levelWidth: CGFloat = 2668
    static let groundHeight: CGFloat = 32

    /// Y-координата поверхности земли — точка, на которую "ставим" объекты.
    private static let groundTop: CGFloat = groundHeight

    static let all: [LevelConfiguration] = [level1, level2, level3]

    // MARK: - Level 1

    static let level1 = LevelConfiguration(
        name: "Level 1",
        sceneSize: sceneSize,
        levelWidth: levelWidth,
        playerStart: CGPoint(x: 100, y: groundTop + 100),
        groundHeight: groundHeight,
        platforms: [
            PlatformDescriptor(
                position: CGPoint(x: 350, y: groundTop + 130),
                size: CGSize(width: 200, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 800, y: groundTop + 230),
                size: CGSize(width: 200, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 1450, y: groundTop + 180),
                size: CGSize(width: 200, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 1950, y: groundTop + 260),
                size: CGSize(width: 200, height: 20)
            ),
        ],
        enemies: [
            EnemyDescriptor(
                position: CGPoint(x: 400, y: groundTop + 20),
                behavior: .stationary
            ),
            EnemyDescriptor(
                position: CGPoint(x: 800, y: groundTop + 20),
                behavior: .patrolling(leftX: 700, rightX: 900, speed: 100)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 1500, y: groundTop + 20),
                behavior: .patrolling(leftX: 1400, rightX: 1600, speed: 120)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 2100, y: groundTop + 20),
                behavior: .stationary
            ),
        ],
        pickups: [
            PickupDescriptor(position: CGPoint(x: 300, y: groundTop + 100),
                             kind: .health),
            PickupDescriptor(position: CGPoint(x: 600, y: groundTop + 100),
                             kind: .bonus(points: 5)),
            PickupDescriptor(position: CGPoint(x: 1000, y: groundTop + 100),
                             kind: .bonus(points: 10)),
            PickupDescriptor(position: CGPoint(x: 1700, y: groundTop + 100),
                             kind: .bonus(points: 15)),
            PickupDescriptor(position: CGPoint(x: 2300, y: groundTop + 100),
                             kind: .health),
        ],
        portal: CGPoint(x: levelWidth - 80, y: groundTop + 40)
    )

    // MARK: - Level 2

    static let level2 = LevelConfiguration(
        name: "Level 2",
        sceneSize: sceneSize,
        levelWidth: levelWidth,
        playerStart: CGPoint(x: 100, y: groundTop + 100),
        groundHeight: groundHeight,
        platforms: [
            PlatformDescriptor(
                position: CGPoint(x: 300, y: groundTop + 130),
                size: CGSize(width: 160, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 650, y: groundTop + 230),
                size: CGSize(width: 160, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 1050, y: groundTop + 130),
                size: CGSize(width: 160, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 1500, y: groundTop + 200),
                size: CGSize(width: 160, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 2000, y: groundTop + 280),
                size: CGSize(width: 160, height: 20)
            ),
        ],
        enemies: [
            EnemyDescriptor(
                position: CGPoint(x: 350, y: groundTop + 20),
                behavior: .patrolling(leftX: 250, rightX: 450, speed: 120)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 700, y: groundTop + 20),
                behavior: .patrolling(leftX: 600, rightX: 800, speed: 150)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 1000, y: groundTop + 20),
                behavior: .stationary
            ),
            EnemyDescriptor(
                position: CGPoint(x: 1600, y: groundTop + 20),
                behavior: .patrolling(leftX: 1500, rightX: 1700, speed: 160)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 2200, y: groundTop + 20),
                behavior: .patrolling(leftX: 2100, rightX: 2300, speed: 180)
            ),
        ],
        pickups: [
            PickupDescriptor(position: CGPoint(x: 500, y: groundTop + 100),
                             kind: .bonus(points: 10)),
            PickupDescriptor(position: CGPoint(x: 900, y: groundTop + 100),
                             kind: .bonus(points: 15)),
            PickupDescriptor(position: CGPoint(x: 1150, y: groundTop + 100),
                             kind: .health),
            PickupDescriptor(position: CGPoint(x: 1800, y: groundTop + 100),
                             kind: .bonus(points: 20)),
            PickupDescriptor(position: CGPoint(x: 2400, y: groundTop + 100),
                             kind: .health),
        ],
        portal: CGPoint(x: levelWidth - 80, y: groundTop + 40)
    )

    // MARK: - Level 3

    static let level3 = LevelConfiguration(
        name: "Level 3",
        sceneSize: sceneSize,
        levelWidth: levelWidth,
        playerStart: CGPoint(x: 100, y: groundTop + 100),
        groundHeight: groundHeight,
        platforms: [
            PlatformDescriptor(
                position: CGPoint(x: 250, y: groundTop + 130),
                size: CGSize(width: 150, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 550, y: groundTop + 230),
                size: CGSize(width: 150, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 850, y: groundTop + 300),
                size: CGSize(width: 150, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 1150, y: groundTop + 230),
                size: CGSize(width: 150, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 1500, y: groundTop + 160),
                size: CGSize(width: 150, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 1850, y: groundTop + 280),
                size: CGSize(width: 150, height: 20)
            ),
            PlatformDescriptor(
                position: CGPoint(x: 2200, y: groundTop + 340),
                size: CGSize(width: 150, height: 20)
            ),
        ],
        enemies: [
            EnemyDescriptor(
                position: CGPoint(x: 300, y: groundTop + 20),
                behavior: .stationary
            ),
            EnemyDescriptor(
                position: CGPoint(x: 500, y: groundTop + 20),
                behavior: .patrolling(leftX: 450, rightX: 600, speed: 180)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 800, y: groundTop + 20),
                behavior: .patrolling(leftX: 750, rightX: 900, speed: 200)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 1100, y: groundTop + 20),
                behavior: .stationary
            ),
            EnemyDescriptor(
                position: CGPoint(x: 1600, y: groundTop + 20),
                behavior: .patrolling(leftX: 1500, rightX: 1700, speed: 210)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 2000, y: groundTop + 20),
                behavior: .patrolling(leftX: 1950, rightX: 2100, speed: 220)
            ),
            EnemyDescriptor(
                position: CGPoint(x: 2400, y: groundTop + 20),
                behavior: .stationary
            ),
        ],
        pickups: [
            PickupDescriptor(position: CGPoint(x: 400, y: groundTop + 100),
                             kind: .bonus(points: 20)),
            PickupDescriptor(position: CGPoint(x: 700, y: groundTop + 100),
                             kind: .bonus(points: 25)),
            PickupDescriptor(position: CGPoint(x: 1000, y: groundTop + 100),
                             kind: .bonus(points: 30)),
            PickupDescriptor(position: CGPoint(x: 1700, y: groundTop + 100),
                             kind: .bonus(points: 35)),
            PickupDescriptor(position: CGPoint(x: 2300, y: groundTop + 100),
                             kind: .health),
        ],
        portal: CGPoint(x: levelWidth - 80, y: groundTop + 40)
    )
}
