//
//  EnemyAnimationState.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 26.07.2026.
//

import CoreGraphics

/// Визуальное состояние врага. Живой враг всё время проигрывает свой цикл —
/// у ходячих это шаг, у неподвижных покачивание; какие именно это кадры,
/// решает вид врага (`AnimationFrames.Enemy`), а не состояние.
/// Направление взгляда сюда не входит — оно отражается отдельно (`EnemyFacing`).
enum EnemyAnimationState: Equatable {
    case alive
    case defeated
}

/// Сторона, в которую «смотрит» враг. В атласе кадры нарисованы вправо,
/// для движения влево узел зеркалится по X — как у игрока.
enum EnemyFacing: Equatable {
    case right
    case left
}

/// Чистая логика анимации врага. Не зависит от SpriteKit — покрыта юнит-тестами.
enum EnemyAnimation {

    /// Направление взгляда по смещению за кадр. Враг не управляется вводом,
    /// поэтому направление берём из фактического сдвига по X; на развороте и
    /// у неподвижных врагов сдвиг нулевой — тогда сохраняем прежнее направление,
    /// чтобы враг не «дёргался» лицом туда-сюда.
    static func facing(dx: CGFloat, current: EnemyFacing) -> EnemyFacing {
        if dx > 0 { return .right }
        if dx < 0 { return .left }
        return current
    }
}
