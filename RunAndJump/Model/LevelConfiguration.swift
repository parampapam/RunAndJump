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
    /// Стиль — чем нарисован уровень: ландшафт, фон и набор декораций.
    /// Каталог по нему находит `StyleCatalogs`; модель знает только идентификатор.
    let style: LevelStyleID
    let sceneSize: CGSize
    let levelWidthInTiles: CGFloat
    let levelHeightInTiles: CGFloat
    let playerStart: TileCoordinate   // нижний-левый угол игрока
    let groundHeight: CGFloat
    let background: BackgroundDescriptor
    let platforms: [PlatformDescriptor]
    let movingPlatforms: [MovingPlatformDescriptor]
    let ladders: [LadderDescriptor]
    let hazards: [HazardDescriptor]
    let enemies: [EnemyDescriptor]
    let pickups: [PickupDescriptor]
    let checkpoints: [CheckpointDescriptor]
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

/// Декларативное описание врага: какой враг и где стоит.
/// Двигается ли он — следует из вида (`EnemyKind.movementStyle`), поэтому
/// параметры патруля нужны только ходячим видам.
struct EnemyDescriptor: Equatable {

    /// Параметры патруля. `leftX`/`rightX` — диапазон X **нижнего-левого угла**
    /// врага в тайлах; `speed` — скорость в пунктах/с.
    struct Patrol: Equatable {
        let leftX: CGFloat
        let rightX: CGFloat
        let speed: CGFloat
    }

    let origin: TileCoordinate   // нижний-левый угол
    let kind: EnemyKind
    /// Нужен только патрулирующим видам; для неподвижных — `nil`.
    let patrol: Patrol?

    /// Итоговое поведение. Вид врага главнее описания: неподвижный вид стоит,
    /// даже если ему по недосмотру задали патруль, а ходячий без параметров
    /// патруля просто остаётся на месте (вместо падения на дефолтный диапазон).
    var behavior: EnemyBehavior {
        guard kind.movementStyle == .patrolling, let patrol else { return .stationary }
        return .patrolling(leftX: patrol.leftX, rightX: patrol.rightX, speed: patrol.speed)
    }

    /// Неподвижный враг: растение или оса.
    static func stationary(_ kind: EnemyKind, at origin: TileCoordinate) -> EnemyDescriptor {
        EnemyDescriptor(origin: origin, kind: kind, patrol: nil)
    }

    /// Патрулирующий враг: краб, бес или снайпер.
    static func patrolling(_ kind: EnemyKind,
                           at origin: TileCoordinate,
                           leftX: CGFloat,
                           rightX: CGFloat,
                           speed: CGFloat) -> EnemyDescriptor {
        EnemyDescriptor(origin: origin,
                        kind: kind,
                        patrol: Patrol(leftX: leftX, rightX: rightX, speed: speed))
    }
}

/// Декларативное описание опасной зоны — озера воды или лавы
/// (нижний-левый угол + размер, в тайлах).
///
/// Прямоугольник — это сразу три вещи: видимая жидкость, зона урона и **проём
/// в земле**. Земля под озером вырезается (`GroundLayout`), а на дне ямы
/// кладётся опора ниже поверхности на `HazardKind.depthInTiles`: игрок
/// проваливается в озеро и выбирается прыжком.
///
/// Поэтому прямоугольник задаётся целыми тайлами и по сетке: обычное озеро —
/// это ряд земли целиком, то есть `y = 0` и высота 1. На дробных границах
/// травяная плитка на краю проёма обрежется, а плитка жидкости сплющится.
struct HazardDescriptor: Equatable {
    let kind: HazardKind
    let rect: TileRect
}

/// Декларативное описание платформы (нижний-левый угол + размер, в тайлах).
struct PlatformDescriptor: Equatable {
    let rect: TileRect
}

/// Декларативное описание подвижной платформы.
///
/// Паузы задаёт список остановок (`MotionStop`), а не одно число «пауза в
/// концах»: платформа может стоять в любой точке маршрута и в каждой — своё
/// время. Место остановки — доля пути (0 = `start`, 1 = `end`), потому что это
/// единственная координата, переживающая сдвиг концов платформы. Пустой список
/// = ход без пауз, а «в конце паузы нет» = остановки для конца просто нет.
struct MovingPlatformDescriptor: Equatable {
    let size: TileSize
    let start: TileCoordinate   // нижний-левый угол в крайней точке
    let end: TileCoordinate
    let speed: CGFloat          // пункты/с
    let stops: [MotionStop]     // где и сколько стоять на маршруте
}

/// Декларативное описание декоративного объекта заднего плана.
/// Описывает, **какой** объект и **где** располагается. Декорации не участвуют
/// в игровой механике — только украшают сцену.
struct DecorationDescriptor: Equatable {
    /// Какая декорация — идентификатор из каталога стиля этого уровня.
    /// Открытый (`DecorationID`), а не `enum`: набор украшений у каждого стиля
    /// свой, и держать их общим списком значило бы запретить стилям различаться.
    /// Опечатку ловит не компилятор, а `LevelValidation`.
    let id: DecorationID
    let origin: TileCoordinate   // нижний-левый угол
}

/// Декларативное описание точки восстановления — флага, мимо которого проходит
/// игрок. Порядок в `LevelConfiguration.checkpoints` — это и есть идентификатор
/// точки: активная запоминается индексом в этом массиве (см. `CheckpointRules`).
///
/// Координата — нижний-левый угол флага, и она же место появления игрока, так
/// что флаг ставится там, где игрок может стоять: на земле (`y: 1`) или на
/// платформе.
struct CheckpointDescriptor: Equatable {
    let origin: TileCoordinate
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
