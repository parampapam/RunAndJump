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

    private var jumpController = JumpController()

    private var ground: SKSpriteNode!
    private var inputController: InputController!
    private var hud: HUDNode!

    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.5, green: 0.7, blue: 0.95, alpha: 1.0)

        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        physicsWorld.contactDelegate = self

        view.isMultipleTouchEnabled = true

        setupGround()
        setupPlayer()
        setupInputController()
        setupHUD()
        setupLevelObjects()
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

    private func setupLevelObjects() {
        let groundTop = ground.size.height // Y верхней грани земли

        // Стационарный враг возле начала пути.
        let stationary = Enemy()
        stationary.position = CGPoint(x: 400, y: groundTop + 20)
        addChild(stationary)

        // Патрулирующий враг в средней части.
        let patrolMovement = PatrollingMovement(leftX: 700, rightX: 900, speed: 100)
        let patrolling = Enemy(movement: patrolMovement)
        patrolling.position = CGPoint(x: 800, y: groundTop + 20)
        addChild(patrolling)

        // Награда здоровья.
        let healthPickup = Pickup(kind: .health)
        healthPickup.position = CGPoint(x: 300, y: groundTop + 100)
        addChild(healthPickup)

        // Бонусные награды.
        let bonus1 = Pickup(kind: .bonus(points: 5))
        bonus1.position = CGPoint(x: 600, y: groundTop + 100)
        addChild(bonus1)

        let bonus2 = Pickup(kind: .bonus(points: 10))
        bonus2.position = CGPoint(x: 1000, y: groundTop + 100)
        addChild(bonus2)

        // Портал в конце.
        let portal = Portal()
        portal.position = CGPoint(x: size.width - 80, y: groundTop + 40)
        addChild(portal)
    }

    // MARK: - Игровой цикл

    override func update(_ currentTime: TimeInterval) {
        lastUpdateTime = currentTime
        player.update()

        // Обновляем все игровые объекты с поведением.
        for child in children {
            if let levelObject = child as? LevelObject {
                levelObject.update(at: currentTime)
            }
        }

        if jumpController.consumeJumpIfPossible(at: currentTime) {
            player.jump()
        }
    }

    private func handle(_ event: GameEvent) {
        playerState = GameRules.apply(event, to: playerState)
        hud.update(with: playerState)

        let outcome = GameRules.outcome(after: event, in: playerState)
        switch outcome {
        case .playing:
            break
        case .died:
            restartLevel()
        case .completed:
            completeLevel()
        }
    }

    private func restartLevel() {
        let newScene = GameScene(size: size)
        newScene.scaleMode = scaleMode
        view?.presentScene(newScene, transition: .fade(withDuration: 0.5))
    }

    private func completeLevel() {
        // Пока просто перезапускаем, но печатаем для понимания.
        // На шаге 6 здесь будет переход к следующему уровню.
        print("Level completed! Bonus points: \(playerState.bonusPoints)")
        let newScene = GameScene(size: size)
        newScene.scaleMode = scaleMode
        view?.presentScene(newScene, transition: .fade(withDuration: 0.5))
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
        jumpController.didPressJump(at: lastUpdateTime)
    }
}


// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = (contact.bodyA, contact.bodyB)

        // Контакт игрока с землёй — обновляем jumpController.
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ground) {
            jumpController.didTouchGround(at: lastUpdateTime)
            return
        }

        // Контакт игрока с врагом.
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.enemy) {
            handle(.enemyHit)
            return
        }

        // Контакт игрока с подбираемой наградой.
        if let pickupBody = bodyOfCategory(PhysicsCategory.pickup, in: bodies), let pickup = pickupBody.node as? Pickup {
            switch pickup.kind {
            case .health:
                handle(.healthPickup)
            case .bonus(let points):
                handle(.bonusPickup(points: points))
            }
            pickup.removeFromParent()
            return
        }

        // Контакт игрока с порталом.
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.portal) {
            handle(.reachedPortal)
            return
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let bodies = (contact.bodyA, contact.bodyB)

        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ground) {
            jumpController.didLeaveGround(at: lastUpdateTime)
        }
    }

    // MARK: - Helpers

    /// Проверяют, что в контакте участвуют две заявленных категории.
    private func matchesPair(_ bodies: (SKPhysicsBody, SKPhysicsBody), _ a: UInt32, _ b: UInt32) -> Bool {
        let combined = bodies.0.categoryBitMask | bodies.1.categoryBitMask
        return combined == (a | b)
    }

    /// Находит тело заданной категории, чтобы достать его узел.
    private func bodyOfCategory(_ category: UInt32, in bodies: (SKPhysicsBody, SKPhysicsBody)) -> SKPhysicsBody? {
        if bodies.0.categoryBitMask == category { return bodies.0 }
        if bodies.1.categoryBitMask == category { return bodies.1 }
        return nil
    }
}
