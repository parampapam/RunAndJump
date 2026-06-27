//
//  Decoration.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.06.2026.
//

import SpriteKit

/// Чисто декоративный объект заднего плана (цветы, а в будущем — кусты, деревья
/// и пр.). Составной: контейнер из плиток-спрайтов, у каждой своя текстура.
/// Не имеет физического тела и ни с чем не взаимодействует: игрок и другие
/// подвижные объекты проходят перед ним. Позади декораций — только фон сцены
/// (см. `ZPosition`).
///
/// `position` узла — нижний-левый угол декорации; спрайты-плитки спозиционированы
/// относительно него (это делает `LevelBuilder`).
final class Decoration: SKNode {

    init(tiles: [SKSpriteNode]) {
        super.init()
        zPosition = ZPosition.decoration
        tiles.forEach(addChild)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
