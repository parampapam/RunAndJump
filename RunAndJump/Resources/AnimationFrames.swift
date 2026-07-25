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

    enum Pickup {
        /// Кадры для каждого вида награды (атлас `Pickups`).
        static func frames(for kind: PickupKind) -> [String] {
            switch kind {
            case .health:
                return [TextureName.Heart.heart0,
                        TextureName.Heart.heart1,
                        TextureName.Heart.heart2,
                        TextureName.Heart.heart3]
            case .coin(.bronze):
                return [TextureName.Coin.bronze0, TextureName.Coin.bronze1,
                        TextureName.Coin.bronze2, TextureName.Coin.bronze3,
                        TextureName.Coin.bronze4, TextureName.Coin.bronze5,
                        TextureName.Coin.bronze6, TextureName.Coin.bronze7]
            case .coin(.silver):
                return [TextureName.Coin.silver0, TextureName.Coin.silver1,
                        TextureName.Coin.silver2, TextureName.Coin.silver3,
                        TextureName.Coin.silver4, TextureName.Coin.silver5,
                        TextureName.Coin.silver6, TextureName.Coin.silver7]
            case .coin(.gold):
                return [TextureName.Coin.gold0, TextureName.Coin.gold1,
                        TextureName.Coin.gold2, TextureName.Coin.gold3,
                        TextureName.Coin.gold4, TextureName.Coin.gold5,
                        TextureName.Coin.gold6, TextureName.Coin.gold7]
            }
        }
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

    enum Pickup {
        /// Монета вращается быстрее, чем «бьётся» сердце.
        static func timePerFrame(for kind: PickupKind) -> TimeInterval {
            switch kind {
            case .health: return 0.18
            case .coin:   return 0.1
            }
        }
    }
}
