//
//  Decoration.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.06.2026.
//

import SpriteKit

/// Чисто декоративный объект заднего плана (цветы, а в будущем — кусты, деревья
/// и пр.). Не имеет физического тела и ни с чем не взаимодействует: игрок и
/// другие подвижные объекты проходят перед ним. Позади декораций — только фон
/// сцены (см. `ZPosition`).
final class Decoration: SKSpriteNode {

    init(texture: SKTexture, size: CGSize) {
        super.init(texture: texture, color: .clear, size: size)
        zPosition = ZPosition.decoration
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
