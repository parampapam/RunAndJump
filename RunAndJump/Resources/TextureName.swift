//
//  TextureName.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 22.06.2026.
//

import Foundation

enum TextureName {
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

    enum Ground {
        static let grassland = "grass tiles (24)"
    }
}
