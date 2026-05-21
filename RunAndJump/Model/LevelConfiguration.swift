//
//  LevelConfiguration.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import CoreGraphics

/// Декларативное описание уровня. Чистые данные, без SpriteKit.
struct LevelConfiguration: Equatable {
    let name: String
    let sceneSize: CGSize
    let levelWidth: CGFloat
    let levelHeight: CGFloat
    let playerStart: CGPoint
    let groundHeight: CGFloat
    let platforms: [PlatformDescriptor]
    let enemies: [EnemyDescriptor]
    let pickups: [PickupDescriptor]
    let portal: CGPoint
}

/// Декларативное описание врага.
struct EnemyDescriptor: Equatable {
    enum Behavior: Equatable {
        case stationary
        case patrolling(leftX: CGFloat, rightX: CGFloat, speed: CGFloat)
    }

    let position: CGPoint
    let behavior: Behavior
}

/// Декларативное описание платформы.
struct PlatformDescriptor: Equatable {
    let position: CGPoint
    let size: CGSize
}

/// Декларативное описание награды.
struct PickupDescriptor: Equatable {
    /// Кажется, что **Kind** здесь дублирует **PickupKind**, но это сделано специально,
    /// потому что **Pickup Kind** — это Runtime свойство. На старте они выглядят одинаково,
    /// но по мере развития игры они могут разойтись.
    enum Kind: Equatable {
        case health
        case bonus(points: Int)
    }

    let position: CGPoint
    let kind: Kind
}
