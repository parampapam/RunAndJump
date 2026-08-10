//
//  PauseButton.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 10.08.2026.
//

import SpriteKit

/// Кнопка паузы в правом верхнем углу HUD.
///
/// Рисуется фигурами, а не картинкой: значок паузы — это две полоски, и ради
/// них не стоит заводить ассет. Область касания заметно больше значка —
/// попадать нужно пальцем, а не пикселем.
final class PauseButton: SKNode {

    var onTap: (() -> Void)?

    override init() {
        super.init()

        isUserInteractionEnabled = true

        // Прозрачная «подушка» касания. Нужна не только пальцу: у пустого
        // SKNode нулевой кадр, и без ребёнка с размером SpriteKit просто не
        // нашёл бы кнопку под касанием.
        addChild(SKSpriteNode(color: .clear, size: Layout.touchArea))

        let backing = SKShapeNode(circleOfRadius: Layout.radius)
        backing.fillColor = Palette.backing
        backing.strokeColor = Palette.stroke
        backing.lineWidth = 1
        addChild(backing)

        for offset in [-Layout.barSpacing, Layout.barSpacing] {
            let bar = SKSpriteNode(color: Palette.bar, size: Layout.barSize)
            bar.position = CGPoint(x: offset, y: 0)
            backing.addChild(bar)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Любое касание, дошедшее до узла, лежит в его области — она и есть кнопка.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onTap?()
    }
}

private enum Layout {
    static let radius: CGFloat = 13
    static let touchArea = CGSize(width: 44, height: 44)
    static let barSize = CGSize(width: 4, height: 13)
    /// Половина расстояния между полосками.
    static let barSpacing: CGFloat = 3.5
}

private enum Palette {
    static let backing = SKColor(white: 0.15, alpha: 0.55)
    static let stroke = SKColor(white: 1, alpha: 0.7)
    static let bar = SKColor(white: 1, alpha: 0.9)
}
