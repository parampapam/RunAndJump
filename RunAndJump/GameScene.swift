//
//  GameScene.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

final class GameScene: SKScene {

    private var player: Player!
    private var playerState: PlayerState = .initial

    private var ground: SKSpriteNode!
    private var inputController: InputController!
    private var hud: HUDNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.5, green: 0.7, blue: 0.95, alpha: 1.0)

        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        physicsWorld.contactDelegate = self

        setupGround()
        setupPlayer()
        setupInputController()
        setupHUD()
    }

    private func setupGround() {
        let groundSize = CGSize(width: size.width, height: 80)
        ground = SKSpriteNode(color: .brown, size: groundSize)
        // Позиционируем по центру нижнего края сцены.
        ground.position = CGPoint(x: size.width / 2, y: groundSize.height / 2)

        let body = SKPhysicsBody(rectangleOf: groundSize)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.ground
        // Земля сама ни с кем не "ищет" контактов — её роль пассивная.
        body.contactTestBitMask = PhysicsCategory.none
        ground.physicsBody = body

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

    private func setupHUD() {
        hud = HUDNode(sceneSize: size)
        hud.update(with: playerState)
        addChild(hud)
    }

    // MARK: - Игровой цикл

    override func update(_ currentTime: TimeInterval) {
        player.update()
    }

    private func handle(_ event: GameEvent) {
        playerState = GameRules.apply(event, to: playerState)
        hud.update(with: playerState)

        if GameRules.isDead(playerState) {
            // Перезапуск сцены — добавим на следующем шаге.
        }
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


// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if categories == (PhysicsCategory.player | PhysicsCategory.ground) {
            player.isOnGround = true
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if categories == (PhysicsCategory.player | PhysicsCategory.ground) {
            player.isOnGround = false
        }
    }
}
