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
    func inputControllerDidReleaseDirection(_ controller: InputController)
    func inputControllerDidPressJump(_ controller: InputController)
}

final class InputController: SKNode {

    weak var delegate: InputControllerDelegate?

    private let leftButton: SKSpriteNode
    private let rightButton: SKSpriteNode
    private let jumpButton: SKSpriteNode

    // Отслеживаем активные касания, чтобы понимать, когда отпустили кнопку.
    private var activeDirectionTouch: UITouch?
    private var activeJumpTouch: UITouch?

    init(sceneSize: CGSize) {
        let buttonSize = CGSize(width: 90, height: 90)

        leftButton = SKSpriteNode(color: .darkGray, size: buttonSize)
        leftButton.alpha = 0.3
        leftButton.position = CGPoint(x: 90, y: 150)
        leftButton.name = "leftButton"

        rightButton = SKSpriteNode(color: .darkGray, size: buttonSize)
        rightButton.alpha = 0.3
        rightButton.position = CGPoint(x: 200, y: 150)
        rightButton.name = "rightButton"

        jumpButton = SKSpriteNode(color: .darkGray, size: buttonSize)
        jumpButton.alpha = 0.3
        jumpButton.position = CGPoint(x: sceneSize.width - 90, y: 150)
        jumpButton.name = "jumpButton"

        super.init()

        // HUD должен быть поверх всего остального в сцене.
        zPosition = 1000

        addChild(leftButton)
        addChild(rightButton)
        addChild(jumpButton)

        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Обработка касаний

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            handleTouchBegan(touch)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            handleTouchEnded(touch)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            handleTouchEnded(touch)
        }
    }

    private func handleTouchBegan(_ touch: UITouch) {
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)

        switch tappedNode.name {
        case "leftButton":
            activeDirectionTouch = touch
            delegate?.inputControllerDidPressLeft(self)
        case "rightButton":
            activeDirectionTouch = touch
            delegate?.inputControllerDidPressRight(self)
        case "jumpButton":
            activeJumpTouch = touch
            delegate?.inputControllerDidPressJump(self)
        default:
            break
        }
    }

    private func handleTouchEnded(_ touch: UITouch) {
        if touch == activeDirectionTouch {
            activeDirectionTouch = nil
            delegate?.inputControllerDidReleaseDirection(self)
        }
        if touch == activeJumpTouch {
            activeJumpTouch = nil
        }
    }
}
