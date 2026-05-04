//
//  GameScene.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

final class GameScene: SKScene {

    private var player: Player!
    private var ground: SKSpriteNode!
    private var inputController: InputController!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.5, green: 0.7, blue: 0.95, alpha: 1.0)

        physicsWorld.gravity = CGVector(dx: 0, dy: -20)

        setupGround()
        setupPlayer()
        setupInputController()
    }

    private func setupGround() {
        let groundSize = CGSize(width: size.width, height: 80)
        ground = SKSpriteNode(color: .brown, size: groundSize)
        // Позиционируем по центру нижнего края сцены.
        ground.position = CGPoint(x: size.width / 2, y: groundSize.height / 2)

        // Статическое физическое тело: не двигается само, но об него можно опереться.
        ground.physicsBody = SKPhysicsBody(rectangleOf: groundSize)
        ground.physicsBody?.isDynamic = false

        addChild(ground)
    }

    private func setupPlayer() {
        player = Player()
        player.position = CGPoint(x: size.width / 2, y: size.height - 100)
        addChild(player)
    }

    private func setupInputController() {
        inputController = InputController(sceneSize: size)
        inputController.delegate = self
        addChild(inputController)
    }

    // MARK: - Игровой цикл

    override func update(_ currentTime: TimeInterval) {
        player.update()
    }

    // Простая проверка приземления: касается ли низ игрока верха земли.
    // На следующем шаге заменим на нормальную систему контактов.
    override func didSimulatePhysics() {
        let playerBottom = player.position.y - player.size.height / 2
        let groundTop = ground.position.y + ground.size.height / 2
        let tolerance: CGFloat = 2
        player.isOnGround = abs(playerBottom - groundTop) < tolerance
    }
}

// MARK: - InputControllerDelegate

extension GameScene: InputControllerDelegate {

    func inputControllerDidPressLeft(_ controller: InputController) {
        player.startMovingLeft()
    }

    func inputControllerDidPressRight(_ controller: InputController) {
        player.startMovingRight()
    }

    func inputControllerDidReleaseDirection(_ controller: InputController) {
        player.stopMoving()
    }

    func inputControllerDidPressJump(_ controller: InputController) {
        player.jump()
    }
}
