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

    enum Checkpoint {
        /// Кадр флага точки восстановления (атлас `Pickups`). Анимации нет —
        /// у флага два статичных состояния, поднят и опущен.
        static func frame(for state: CheckpointState) -> String {
            switch state {
            case .raised:  return TextureName.Flag.Green.raised
            case .lowered: return TextureName.Flag.Green.lowered
            }
        }
    }

    enum Hazard {
        /// Кадры поверхности озера (атлас `Hazards`).
        static func frames(for kind: HazardKind) -> [String] {
            switch kind {
            case .water:
                return [TextureName.Hazard.water0, TextureName.Hazard.water1]
            case .lava:
                return [TextureName.Hazard.lava0, TextureName.Hazard.lava1]
            }
        }
    }

    enum Enemy {
        /// Кадры врага для его состояния (атлас `Enemies`). Живой цикл у ходячих —
        /// шаг, у неподвижных — покачивание; поверженный враг — один кадр.
        static func frames(for kind: EnemyKind, state: EnemyAnimationState) -> [String] {
            switch state {
            case .alive:   return aliveFrames(for: kind)
            case .defeated: return [defeatedFrame(for: kind)]
            }
        }

        private static func aliveFrames(for kind: EnemyKind) -> [String] {
            switch kind {
            case .crab:
                return [TextureName.Enemy.crab0, TextureName.Enemy.crab1,
                        TextureName.Enemy.crab2, TextureName.Enemy.crab3]
            case .imp:
                return [TextureName.Enemy.imp0, TextureName.Enemy.imp1]
            case .sniper:
                return [TextureName.Enemy.sniper0, TextureName.Enemy.sniper1]
            case .plant:
                return [TextureName.Enemy.plant0, TextureName.Enemy.plant1,
                        TextureName.Enemy.plant2, TextureName.Enemy.plant3]
            case .wasp:
                return [TextureName.Enemy.wasp0, TextureName.Enemy.wasp1]
            }
        }

        private static func defeatedFrame(for kind: EnemyKind) -> String {
            switch kind {
            case .crab:   return TextureName.Enemy.crabDefeated
            case .imp:    return TextureName.Enemy.impDefeated
            case .sniper: return TextureName.Enemy.sniperDefeated
            case .plant:  return TextureName.Enemy.plantDefeated
            case .wasp:   return TextureName.Enemy.waspDefeated
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

    enum Hazard {
        /// Вода колышется лениво, лава кипит заметно живее.
        static func timePerFrame(for kind: HazardKind) -> TimeInterval {
            switch kind {
            case .water: return 0.33
            case .lava:  return 0.2
            }
        }
    }

    enum Enemy {
        /// Темп цикла задаёт характер врага: оса машет крыльями почти без пауз,
        /// растение лениво покачивается, ходячие — в такт шагу.
        static func timePerFrame(for kind: EnemyKind) -> TimeInterval {
            switch kind {
            case .crab:   return 0.12
            case .imp:    return 0.15
            case .sniper: return 0.2
            case .plant:  return 0.3
            case .wasp:   return 0.08
            }
        }
    }
}
