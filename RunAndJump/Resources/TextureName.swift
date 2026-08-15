//
//  TextureName.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 22.06.2026.
//

import Foundation

enum TextureName {
    /// Фон сцены. Каждый слой — отдельный Image Set, а не кадр в атласе:
    /// слои рисуются по одному, каждый со своим `zPosition`, и упаковывать их
    /// вместе незачем.
    enum Background {
        static let daySky = "bg_fill_day"
        static let hills = "bg_hills"
        static let mountains = "bg_mountains"
        static let clouds = "bg_clouds"
    }

    enum Player {
        static let idle0 = "player_idle_0"
        static let idle1 = "player_idle_1"
        static let walk0 = "player_walk_0"
        static let walk1 = "player_walk_1"
        static let jump  = "player_jump"
    }

    enum Flower {
        static let purple = "grass tiles (14)"
        static let yellow = "grass tiles (34)"
        static let white = "grass tiles (49)"
        static let pink = "grass tiles (63)"
    }

    enum Mushroom {
        static let wide = "grass tiles (8)"
        static let tall = "grass tiles (55)"
    }

    enum Arrow {
        static let right = "grass tiles (23)"
        static let left = "grass tiles (16)"
    }

    enum Checkpoint {
        static let active = "flag_green_raised"
        static let inactive = "flag_green_down"
    }

    enum Grass {
        enum Short {
            static let dark = "grass tiles (10)"
            static let light = "grass tiles (53)"
        }
        enum Tall {
            static let dark = "grass tiles (56)"
            static let light = "grass tiles (35)"
        }
    }

    enum Bush {
        enum Small {
            static let dark = "grass tiles (41)"
            static let light = "grass tiles (25)"
        }
        enum Big {
            enum Dark {
                static let left = "grass tiles (54)"
                static let middle = "grass tiles (29)"
                static let right = "grass tiles (40)"
            }
            enum Light {
                static let left = "grass tiles (13)"
                static let middle = "grass tiles (30)"
                static let right = "grass tiles (4)"
            }
        }
    }

    enum Tree {
        enum Dark {
            static let top = "grass tiles (62)"
            static let bottom = "grass tiles (61)"
            static let trunk = "grass tiles (18)"
        }
        enum Light {
            static let top = "grass tiles (38)"
            static let bottom = "grass tiles (39)"
            static let trunk = "grass tiles (18)"
        }
    }

    enum Ladder {
        static let up = "town tiles (53)"
        static let up_75pct = "town tiles (53) 90px"
        static let up_50pct = "town tiles (53) 60px"
        static let up_25pct = "town tiles (53) 30px"
        static let middle = "town tiles (44)"
        static let bottom = "town tiles (57)"
    }

    enum Platform {
        static let left = "grass tiles (52)"
        static let middle = "grass tiles (57)"
        static let right = "grass tiles (6)"
    }

    enum Ground {
        static let grassland = "grass tiles (24)"
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
