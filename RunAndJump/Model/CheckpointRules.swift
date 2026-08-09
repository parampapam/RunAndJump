//
//  CheckpointRules.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 08.08.2026.
//

import CoreGraphics

/// Состояние точки восстановления. Активная — текущая точка,
/// в ней игрок появится после гибели; все остальные на уровне неактивные.
enum CheckpointState: Equatable {
    case active
    case inactive
}

/// Что делать, когда игрок прошёл мимо флага.
enum CheckpointActivation: Equatable {
    /// Флаг становится текущей точкой восстановления (и поднимается).
    case activate
    /// Игрок снова прошёл мимо уже поднятого флага — ничего не меняется.
    case ignore
}

/// Точки восстановления уровня: какая из них активна, где возрождается игрок
/// и что происходит при проходе мимо флага. Чистые правила, без SpriteKit.
///
/// Активная точка хранится **индексом** в `LevelConfiguration.checkpoints`,
/// а не координатой: индекс переживает пересоздание сцены (лежит в
/// `GameProgress`), а координату всегда можно достать из конфигурации уровня.
enum CheckpointRules {

    /// Где игрок появляется на уровне: у последнего пройденного флага, а до
    /// первого — на старте уровня. Неизвестный индекс (описание уровня
    /// изменилось) тоже откатывается на старт, а не роняет игру.
    static func respawnOrigin(checkpoints: [CheckpointDescriptor],
                              levelStart: TileCoordinate,
                              activated index: Int?) -> TileCoordinate {
        guard let index, checkpoints.indices.contains(index) else { return levelStart }
        return checkpoints[index].origin
    }

    /// Реакция на проход мимо флага: активируем, если это не текущая точка.
    static func activation(touched index: Int, active: Int?) -> CheckpointActivation {
        index == active ? .ignore : .activate
    }

    /// Состояние флага при активной точке `active`: поднят ровно один — текущий.
    static func state(of index: Int, active: Int?) -> CheckpointState {
        index == active ? .active : .inactive
    }
}
