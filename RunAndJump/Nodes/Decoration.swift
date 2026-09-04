//
//  Decoration.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.06.2026.
//

import SpriteKit

/// Чисто декоративный объект: цветы, кусты, деревья, а в других стилях —
/// факелы и бочки. Составной: контейнер из плиток-спрайтов, у каждой своя
/// текстура (и, возможно, своя анимация).
///
/// Не имеет физического тела и ни с чем не взаимодействует. Слой отрисовки
/// выбирает `DecorationLayer`: `back` — позади игрока (там же, где раньше были
/// все декорации), `front` — перед ним.
///
/// Узел ничего не решает: спрайты уже собраны, размещены и, если надо,
/// анимированы — всё это делает `LevelBuilder` по каталогу стиля. Про каталог
/// `Decoration` не знает ничего.
///
/// `position` узла — нижний-левый угол декорации; спрайты-плитки спозиционированы
/// относительно него.
final class Decoration: SKNode {

    init(tiles: [SKSpriteNode], layer: DecorationLayer) {
        super.init()
        zPosition = layer == .back ? ZPosition.decorationBack : ZPosition.decorationFront
        tiles.forEach(addChild)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
