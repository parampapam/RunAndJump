//
//  InputController.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

protocol InputControllerDelegate: AnyObject {
    func inputControllerDidPressLeft(_ controller: InputController)
    func inputControllerDidPressRight(_ controller: InputController)
    func inputControllerDidReleaseHorizontal(_ controller: InputController)

    func inputControllerDidPressUp(_ controller: InputController)
    func inputControllerDidPressDown(_ controller: InputController)
    func inputControllerDidReleaseVertical(_ controller: InputController)

    func inputControllerDidPressJump(_ controller: InputController)
}

final class InputController: SKNode {

    weak var delegate: InputControllerDelegate?

    private let leftButton: SKSpriteNode
    private let rightButton: SKSpriteNode
    private let upButton: SKSpriteNode
    private let downButton: SKSpriteNode
    private let jumpButton: SKSpriteNode

    // Независимые слоты по осям: горизонтальная, вертикальная, прыжок.
    // Это позволяет игроку зажимать кнопки разных осей одновременно
    // (например, «вверх по лестнице» + «вправо»).
    private var activeHorizontalTouch: UITouch?
    private var activeVerticalTouch: UITouch?
    private var activeJumpTouch: UITouch?

    init(sceneSize: CGSize) {
        let buttonSize = CGSize(width: 64, height: 64)

        // D-pad: крест из четырёх кнопок слева.
        // Центр креста: x=160, y=96
        leftButton = SKSpriteNode(color: .darkGray, size: buttonSize)
        leftButton.alpha = 0.3
        leftButton.position = CGPoint(x: buttonSize.width * 1.5, y: buttonSize.height * 1.5)
        leftButton.name = "leftButton"

        rightButton = SKSpriteNode(color: .darkGray, size: buttonSize)
        rightButton.alpha = 0.3
        rightButton.position = CGPoint(x: buttonSize.width * 3.5, y: buttonSize.height * 1.5)
        rightButton.name = "rightButton"

        // Вверх и вниз — центрально между левой и правой.
        upButton = SKSpriteNode(color: .darkGray, size: buttonSize)
        upButton.alpha = 0.3
        upButton.position = CGPoint(x: buttonSize.width * 2.5, y: buttonSize.height * 2.5)
        upButton.name = "upButton"

        downButton = SKSpriteNode(color: .darkGray, size: buttonSize)
        downButton.alpha = 0.3
        downButton.position = CGPoint(x: buttonSize.width * 2.5, y: buttonSize.height * 0.5)
        downButton.name = "downButton"

        jumpButton = SKSpriteNode(color: .darkGray, size: buttonSize)
        jumpButton.alpha = 0.3
        jumpButton.position = CGPoint(x: sceneSize.width - buttonSize.width * 1.5, y: buttonSize.height * 1.5)
        jumpButton.name = "jumpButton"

        super.init()

        zPosition = 1000

        addChild(leftButton)
        addChild(rightButton)
        addChild(upButton)
        addChild(downButton)
        addChild(jumpButton)

        addLabel("←", to: leftButton)
        addLabel("→", to: rightButton)
        addLabel("↑", to: upButton)
        addLabel("↓", to: downButton)
        addLabel("↑", to: jumpButton)

        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addLabel(_ text: String, to button: SKSpriteNode) {
        let label = SKLabelNode(text: text)
        label.fontSize = 24
        label.fontColor = .white
        label.alpha = 0.8
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.isUserInteractionEnabled = false
        button.addChild(label)
    }

    // MARK: - Обработка касаний

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handleTouchBegan(touch) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handleTouchEnded(touch) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handleTouchEnded(touch) }
    }

    private func handleTouchBegan(_ touch: UITouch) {
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)
        // atPoint может вернуть дочерний узел (SKLabelNode), берём имя с учётом этого.
        let name = tappedNode.name ?? tappedNode.parent?.name

        switch name {
        case "leftButton":
            activeHorizontalTouch = touch
            delegate?.inputControllerDidPressLeft(self)
        case "rightButton":
            activeHorizontalTouch = touch
            delegate?.inputControllerDidPressRight(self)
        case "jumpButton":
            activeJumpTouch = touch
            delegate?.inputControllerDidPressJump(self)
        case "upButton":
            activeVerticalTouch = touch
            delegate?.inputControllerDidPressUp(self)
        case "downButton":
            activeVerticalTouch = touch
            delegate?.inputControllerDidPressDown(self)
        default:
            break
        }
    }

    private func handleTouchEnded(_ touch: UITouch) {
        if touch == activeHorizontalTouch {
            activeHorizontalTouch = nil
            delegate?.inputControllerDidReleaseHorizontal(self)
        }
        if touch == activeVerticalTouch {
            activeVerticalTouch = nil
            delegate?.inputControllerDidReleaseVertical(self)
        }
        if touch == activeVerticalTouch {
            activeVerticalTouch = nil
            delegate?.inputControllerDidReleaseVertical(self)
        }
        if touch == activeJumpTouch {
            activeJumpTouch = nil
        }
    }
}
