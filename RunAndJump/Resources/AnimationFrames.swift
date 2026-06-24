//
//  AnimationFrames.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.06.2026.
//

import Foundation

// Последовательности кадров анимации.
enum AnimationFrames {

    enum Player {
        static let byState: [PlayerAnimationState: [String]] = [
            .idle:    [TextureName.Player.idle0, TextureName.Player.idle1],
            .running: [TextureName.Player.walk0, TextureName.Player.walk1],
            .jumping: [TextureName.Player.jump]
        ]
    }
}

/// Длительность одного кадра анимации для каждого состояния, секунды.
enum AnimationDuration {
    /// Запасное значение для состояний, не указанных в `byState`.
    static let fallback: TimeInterval = 0.15

    enum Player {
        static let byState: [PlayerAnimationState: TimeInterval] = [
            .idle:    2,
            .running: 0.08,
            .jumping: 0.1
        ]
    }
}
