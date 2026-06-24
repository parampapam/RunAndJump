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

    enum Ground {
        static let grass = "grass tiles (24)"
        static let flower1 = "grass tiles (14)"
        static let flower2 = "grass tiles (34)"
        static let flower3 = "grass tiles (49)"
        static let flower4 = "grass tiles (63)"

        // TODO: добавить ассеты в атлас Grassland. Пока имена-заглушки — если
        // поставить такую декорацию на уровень до появления ассета, SpriteKit
        // нарисует красный плейсхолдер.
        static let bush = "bush"
        static let tree = "tree"
    }
}
