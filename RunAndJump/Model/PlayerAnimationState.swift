//
//  PlayerAnimationState.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 20.06.2026.
//

import CoreGraphics

/// Визуальное состояние анимации игрока. Не знает о направлении взгляда —
/// влево/вправо отражается отдельно (см. `PlayerFacing`).
enum PlayerAnimationState: Equatable {
    case idle
    case running
    case jumping
}

/// Сторона, в которую «смотрит» игрок. В атласе кадры нарисованы вправо,
/// для движения влево узел зеркалится по X.
enum PlayerFacing: Equatable {
    case right
    case left
}

/// Чистая логика выбора анимации и направления по физическим признакам игрока.
/// Не зависит от SpriteKit — покрыта юнит-тестами.
enum PlayerAnimation {

    /// Состояние анимации: в воздухе — прыжок; на опоре — бег при горизонтальном
    /// вводе, иначе покой. Флаг `isOnGround` стабилен (опоры с `restitution = 0`
    /// не дают микро-баунса), поэтому подтверждать полёт скоростью не нужно — и
    /// заодно нет ложного кадра покоя на вершине прыжка, где `vy ≈ 0`.
    static func state(isOnGround: Bool, horizontalInput: CGFloat) -> PlayerAnimationState {
        guard isOnGround else { return .jumping }
        return horizontalInput == 0 ? .idle : .running
    }

    /// Направление взгляда. При нулевом вводе сохраняем прежнее, чтобы
    /// стоящий игрок не «прыгал» лицом туда-сюда.
    static func facing(horizontalInput: CGFloat, current: PlayerFacing) -> PlayerFacing {
        if horizontalInput > 0 { return .right }
        if horizontalInput < 0 { return .left }
        return current
    }
}
