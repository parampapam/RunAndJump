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
        //
        // Дерево — 1 плитка в ширину, 2 в высоту (разные текстуры снизу/сверху).
        static let treeBottom = "tree_bottom"
        static let treeTop = "tree_top"
        // Куст — 3 плитки в ширину, 1 в высоту.
        static let bushLeft = "bush_left"
        static let bushMiddle = "bush_middle"
        static let bushRight = "bush_right"
    }
}
