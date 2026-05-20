//
//  HUDNode.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 05.05.2026.
//

import SpriteKit

final class HUDNode: SKSpriteNode {

    private let fullTexture = SKTexture(imageNamed: "heart_full")
    private let emptyTexture = SKTexture(imageNamed: "heart_empty")

    private let maxLives = 10

    private let bonusLabel: SKLabelNode
    private let menuButton: SKSpriteNode
    private var heartNodes: [SKSpriteNode] = []

    init(sceneSize: CGSize) {
        let barSize = CGSize(width: sceneSize.width * 0.85, height: 32)

        bonusLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bonusLabel.fontSize = barSize.height * 0.6
        bonusLabel.fontColor = .darkGray
        bonusLabel.horizontalAlignmentMode = .left
        bonusLabel.verticalAlignmentMode = .center
        bonusLabel.position = CGPoint(x: CGFloat(maxLives) * 18 * 1.06 + 90, y: 0)

        menuButton = SKSpriteNode(imageNamed: "menu_button")
        menuButton.size = CGSize(width: 18, height: 18)
        menuButton.position = CGPoint(x: barSize.width - 18, y: 0)

        super.init(texture: nil, color: UIColor(red: 138, green: 138, blue: 138, alpha: 1), size: barSize)

        anchorPoint = .init(x: 0, y: 0.5)
        position = CGPoint(x: sceneSize.width / 2 - barSize.width / 2 , y: sceneSize.height - barSize.height)
        zPosition = 1000
        addChild(bonusLabel)
        addChild(menuButton)

        setupHearts()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHearts() {
        let heartSize = CGSize(width: 18, height: 18)
        let spacing = heartSize.width * 1.06
        let startX = heartSize.width

        for i in 0..<maxLives {
            let heart = SKSpriteNode(texture: fullTexture)
            heart.size = heartSize
            heart.position = CGPoint(x: startX + CGFloat(i) * spacing, y: 0)
            addChild(heart)
            heartNodes.append(heart)
        }
    }

    func update(with state: PlayerState) {
        for (i, heart) in heartNodes.enumerated() {
            heart.texture = i < state.health ? fullTexture : emptyTexture
        }

        bonusLabel.text = "Bonus: \(state.bonusPoints)"
    }
}
