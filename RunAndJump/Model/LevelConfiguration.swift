//
//  LevelConfiguration.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import CoreGraphics

/// Декларативное описание уровня. Чистые данные, без SpriteKit.
/// Координаты объектов — в тайлах, привязка к нижнему-левому углу.
struct LevelConfiguration: Equatable {
    let name: String
    let sceneSize: CGSize
    let levelWidthInTiles: CGFloat
    let levelHeightInTiles: CGFloat
    let playerStart: TileCoordinate   // нижний-левый угол игрока
    let groundHeight: CGFloat
    let platforms: [PlatformDescriptor]
    let movingPlatforms: [MovingPlatformDescriptor]
    let ladders: [LadderDescriptor]
    let enemies: [EnemyDescriptor]
    let pickups: [PickupDescriptor]
    let decorations: [DecorationDescriptor]
    let portal: TileCoordinate        // нижний-левый угол портала

    /// Размер уровня в пикселях
    var levelWidth: CGFloat { levelWidthInTiles * WorldMetrics.tileSize }
    var levelHeight: CGFloat { levelHeightInTiles * WorldMetrics.tileSize }
}

/// Декларативное описание лестницы (нижний-левый угол + размер, в тайлах).
struct LadderDescriptor: Equatable {
    let origin: TileCoordinate
    let height: CGFloat
}

/// Декларативное описание врага.
struct EnemyDescriptor: Equatable {
    enum Behavior: Equatable {
        case stationary
        /// Патруль между двумя X. `leftX`/`rightX` — диапазон X **нижнего-левого
        /// угла** врага в тайлах; `speed` — скорость в пунктах/с.
        case patrolling(leftX: CGFloat, rightX: CGFloat, speed: CGFloat)
    }

    let origin: TileCoordinate   // нижний-левый угол
    let behavior: Behavior
}

/// Декларативное описание платформы (нижний-левый угол + размер, в тайлах).
struct PlatformDescriptor: Equatable {
    let rect: TileRect
}

/// Декларативное описание подвижной платформы.
struct MovingPlatformDescriptor: Equatable {
    let size: TileSize
    let start: TileCoordinate   // нижний-левый угол в крайней точке
    let end: TileCoordinate
    let speed: CGFloat          // пункты/с
    let pauseDuration: Double   // задержка в крайних точках, секунды
}

/// Декларативное описание декоративного объекта заднего плана.
/// Описывает, **какой** объект и **где** располагается. Декорации не участвуют
/// в игровой механике — только украшают сцену.
struct DecorationDescriptor: Equatable {
    let kind: DecorationKind
    let origin: TileCoordinate   // нижний-левый угол
}

/// Вид декорации. Пока это цветы и заготовки под куст/дерево.
/// Декорация — составной объект из плиток: занимаемый габарит и текстуры
/// каждой плитки задаёт раскладка `DecorationTiles` (в слое ресурсов), поэтому
/// модель знает только *какой* объект, а не из чего он нарисован.
enum DecorationKind: Equatable {
    case purpleFlower
    case yellowFlower
    case whiteFlower
    case pinkFlower
    case bigLightBush
    case bigDarkBush
    case smallLightBush
    case smallDarkBush
    case darkTree
    case tallDarkTree
    case shortLightGrass
    case shortDarkGrass
    case tallLightGrass
    case tallDarkGrass
    case lightTree
    case tallLightTree
    case leftArrow
    case rightArrow
}

/// Декларативное описание награды.
struct PickupDescriptor: Equatable {
    /// Кажется, что **Kind** здесь дублирует **PickupKind**, но это сделано специально,
    /// потому что **Pickup Kind** — это Runtime свойство. На старте они выглядят одинаково,
    /// но по мере развития игры они могут разойтись.
    enum Kind: Equatable {
        case health
        case coin(CoinTier)
    }

    let origin: TileCoordinate   // нижний-левый угол
    let kind: Kind
}
