//
//  TextureName.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 22.06.2026.
//

import Foundation

/// Имена текстур, **не зависящих от стиля**: игрок, враги, снаряд, награды,
/// флаг точки восстановления и поверхность озёр. Их атласы общие на всю игру.
///
/// Всё, что стиль вправе перерисовать — ландшафт, фон и декорации, — живёт не
/// здесь, а в каталоге стиля (`StyleCatalog`). Граница проведена намеренно:
/// иначе к третьему стилю пришлось бы рисовать своего игрока каждому.
enum TextureName {

    enum Player {
        static let idle0 = "player_idle_0"
        static let idle1 = "player_idle_1"
        static let walk0 = "player_walk_0"
        static let walk1 = "player_walk_1"
        static let jump  = "player_jump"
    }

    enum Checkpoint {
        static let active = "flag_green_raised"
        static let inactive = "flag_green_down"
    }

    /// Поверхность опасных зон (атлас `Hazards`): два кадра на каждую жидкость,
    /// волны на них сдвинуты — по ним и «бежит» рябь.
    enum Hazard {
        static let water0 = "grass tiles (12)-0"
        static let water1 = "grass tiles (12)-1"
        static let lava0 = "volcano tiles (9)-0"
        static let lava1 = "volcano tiles (9)-1"
    }

    enum Coin {
        static let bronze0 = "coin_bronze_0"
        static let bronze1 = "coin_bronze_1"
        static let bronze2 = "coin_bronze_2"
        static let bronze3 = "coin_bronze_3"
        static let bronze4 = "coin_bronze_4"
        static let bronze5 = "coin_bronze_5"
        static let bronze6 = "coin_bronze_6"
        static let bronze7 = "coin_bronze_7"
        static let silver0 = "coin_silver_0"
        static let silver1 = "coin_silver_1"
        static let silver2 = "coin_silver_2"
        static let silver3 = "coin_silver_3"
        static let silver4 = "coin_silver_4"
        static let silver5 = "coin_silver_5"
        static let silver6 = "coin_silver_6"
        static let silver7 = "coin_silver_7"
        static let gold0 = "coin_gold_0"
        static let gold1 = "coin_gold_1"
        static let gold2 = "coin_gold_2"
        static let gold3 = "coin_gold_3"
        static let gold4 = "coin_gold_4"
        static let gold5 = "coin_gold_5"
        static let gold6 = "coin_gold_6"
        static let gold7 = "coin_gold_7"
    }

    enum Enemy {
        static let crab0 = "crab_walk_0"
        static let crab1 = "crab_walk_1"
        static let crab2 = "crab_walk_2"
        static let crab3 = "crab_walk_3"
        static let crabDefeated = "crab_defeated"
        static let imp0 = "imp_walk_0"
        static let imp1 = "imp_walk_1"
        static let impDefeated = "imp_defeated"
        static let sniper0 = "sniper_walk_0"
        static let sniper1 = "sniper_walk_1"
        static let sniperDefeated = "sniper_defeated"
        static let sniperProjectile = "sniper_projectile"
        static let plant0 = "plant_idle_0"
        static let plant1 = "plant_idle_1"
        static let plant2 = "plant_idle_2"
        static let plant3 = "plant_idle_3"
        static let plantDefeated = "plant_defeated"
        static let wasp0 = "wasp_idle_0"
        static let wasp1 = "wasp_idle_1"
        static let waspDefeated = "wasp_defeated"
    }

    enum Heart {
        static let heart0 = "heart_0"
        static let heart1 = "heart_1"
        static let heart2 = "heart_2"
        static let heart3 = "heart_3"
    }
}
