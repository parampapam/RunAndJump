//
//  HUDNode.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 05.05.2026.
//

import SpriteKit

final class HUDNode: SKNode {

    private let healthLabel: SKLabelNode
    private let bonusLabel: SKLabelNode

    init(sceneSize: CGSize) {
        healthLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        healthLabel.text = "Health: 0"
        healthLabel.fontSize = 24
        healthLabel.fontColor = .white
        healthLabel.horizontalAlignmentMode = .left
        healthLabel.position = CGPoint(x: 20, y: sceneSize.height - 110)

        bonusLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bonusLabel.fontSize = 24
        bonusLabel.fontColor = .white
        bonusLabel.horizontalAlignmentMode = .left
        bonusLabel.position = CGPoint(x: 20, y: sceneSize.height - 140)

        super.init()

        zPosition = 1000
        addChild(healthLabel)
        addChild(bonusLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with state: PlayerState) {
        healthLabel.text = "Health: \(state.health)"
        bonusLabel.text = "Bonus: \(state.bonusPoints)"
    }
}
