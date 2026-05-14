//
//  Levels.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import CoreGraphics

enum Levels {

    static let sceneSize = CGSize(width: 1334, height: 750)
    static let groundHeight: CGFloat = 80

    /// Y-координата поверхности земли — точка, на которую "ставим" объекты.
    private static let groundTop: CGFloat = groundHeight

    static let all: [LevelConfiguration] = [level1, level2, level3]

    // MARK: - Level 1

    static let level1 = LevelConfiguration(
        name: "Level 1",
        sceneSize: sceneSize,
        playerStart: CGPoint(x: 100, y: groundTop + 100),
        groundHeight: groundHeight,
        enemies: [
            EnemyDescriptor(
                position: CGPoint(x: 400, y: groundTop + 20),
                behavior: .stationary
            ),
            EnemyDescriptor(
                position: CGPoint(x: 800, y: groundTop + 20),
                behavior: .patrolling(leftX: 700, rightX: 900, speed: 100)
            ),
        ],
        pickups: [
            PickupDescriptor(position: CGPoint(x: 300, y: groundTop + 100),
                             kind: .health),
            PickupDescriptor(position: CGPoint(x: 600, y: groundTop + 100),
                             kind: .bonus(points: 5)),
            PickupDescriptor(position: CGPoint(x: 1000, y: groundTop + 100),
                             kind: .bonus(points: 10)),
        ],
        portal: CGPoint(x: sceneSize.width - 80, y: groundTop + 40)
    )

    // MARK: - Level 2

    static let level2 = LevelConfiguration(
        name: "Level 2",
        sceneSize: sceneSize,
        playerStart: CGPoint(x: 100, y: groundTop + 100),
        groundHeight: groundHeight,
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
        ],
        pickups: [
            PickupDescriptor(position: CGPoint(x: 500, y: groundTop + 100),
                             kind: .bonus(points: 10)),
            PickupDescriptor(position: CGPoint(x: 900, y: groundTop + 100),
                             kind: .bonus(points: 15)),
            PickupDescriptor(position: CGPoint(x: 1150, y: groundTop + 100),
                             kind: .health),
        ],
        portal: CGPoint(x: sceneSize.width - 80, y: groundTop + 40)
    )

    // MARK: - Level 3

    static let level3 = LevelConfiguration(
        name: "Level 3",
        sceneSize: sceneSize,
        playerStart: CGPoint(x: 100, y: groundTop + 100),
        groundHeight: groundHeight,
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
        ],
        pickups: [
            PickupDescriptor(position: CGPoint(x: 400, y: groundTop + 100),
                             kind: .bonus(points: 20)),
            PickupDescriptor(position: CGPoint(x: 700, y: groundTop + 100),
                             kind: .bonus(points: 25)),
            PickupDescriptor(position: CGPoint(x: 1000, y: groundTop + 100),
                             kind: .bonus(points: 30)),
        ],
        portal: CGPoint(x: sceneSize.width - 80, y: groundTop + 40)
    )
}
