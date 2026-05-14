//
//  VictoryScene.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import SpriteKit

@MainActor
final class VictoryScene: SKScene {

    private let totalBonusPoints: Int

    init(size: CGSize, totalBonusPoints: Int) {
        self.totalBonusPoints = totalBonusPoints
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)

        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text = "Victory!"
        title.fontSize = 72
        title.fontColor = .yellow
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        addChild(title)

        let score = SKLabelNode(fontNamed: "Helvetica-Bold")
        score.text = "Bonus points: \(totalBonusPoints)"
        score.fontSize = 36
        score.fontColor = .white
        score.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        addChild(score)

        let hint = SKLabelNode(fontNamed: "Helvetica")
        hint.text = "Tap to play again"
        hint.fontSize = 24
        hint.fontColor = .lightGray
        hint.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        addChild(hint)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let firstLevel = Levels.all[0]
        let scene = GameScene(configuration: firstLevel, progress: .initial)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .fade(withDuration: 0.5))
    }
}
