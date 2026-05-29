//
//  GameScene.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

final class GameScene: SKScene {

    // MARK: - Конфигурация и состояние

    private let configuration: LevelConfiguration
    private let progress: GameProgress

    private var playerState: PlayerState
    private var jumpController = JumpController()
    private var ladderController = LadderController()
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Узлы

    private var player: Player!
    private var ground: SKSpriteNode!
    private var inputController: InputController!
    private var hud: HUDNode!
    private var cameraNode: SKCameraNode!
    private weak var currentLadder: Ladder?

    // MARK: - Init

    init(configuration: LevelConfiguration, progress: GameProgress) {
        self.configuration = configuration
        self.progress = progress
        self.playerState = GameProgressRules.initialPlayerState(for: progress)
        super.init(size: configuration.sceneSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Жизненный цикл

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.5, green: 0.7, blue: 0.95, alpha: 1.0)

        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        physicsWorld.contactDelegate = self

        view.isMultipleTouchEnabled = true

        setupCamera()
        setupGround()
        setupBoundaries()
        setupPlayer()
        setupInputController()
        setupHUD()
        setupLevelObjects()
    }

    // MARK: - Setup

    private func setupCamera() {
        cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func setupGround() {
        let groundSize = CGSize(width: configuration.levelWidth, height: configuration.groundHeight)
        ground = SKSpriteNode(color: .brown, size: groundSize)
        ground.position = CGPoint(x: configuration.levelWidth / 2, y: groundSize.height / 2)

        let body = SKPhysicsBody(rectangleOf: groundSize)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.ground
        // Земля сама ни с кем не "ищет" контактов — её роль пассивная.
        body.contactTestBitMask = PhysicsCategory.none
        ground.physicsBody = body

        addChild(ground)
    }

    private func setupBoundaries() {
        let wallThickness: CGFloat = 4
        let wallHeight = configuration.levelHeight

        for xPos in [wallThickness / 2, configuration.levelWidth - wallThickness / 2] {
            let wall = SKSpriteNode(color: .clear, size: CGSize(width: wallThickness, height: wallHeight))
            wall.position = CGPoint(x: xPos, y: wallHeight / 2)
            let body = SKPhysicsBody(rectangleOf: wall.size)
            body.isDynamic = false
            body.categoryBitMask = PhysicsCategory.wall
            body.contactTestBitMask = PhysicsCategory.none
            wall.physicsBody = body
            addChild(wall)
        }
    }

    private func setupPlayer() {
        player = Player()
        player.position = configuration.playerStart
        addChild(player)
    }

    private func setupInputController() {
        inputController = InputController(sceneSize: size)
        inputController.delegate = self
        // Кнопки расположены относительно левого нижнего угла — смещаем узел туда.
        inputController.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        cameraNode.addChild(inputController)
    }

    private func setupHUD() {
        hud = HUDNode(sceneSize: size)
        hud.update(with: playerState)
        cameraNode.addChild(hud)
    }

    private func setupLevelObjects() {
        for platformDescriptor in configuration.platforms {
            addChild(LevelBuilder.makePlatform(from: platformDescriptor))
        }
        for enemyDescriptor in configuration.enemies {
            addChild(LevelBuilder.makeEnemy(from: enemyDescriptor))
        }
        for pickupDescriptor in configuration.pickups {
            addChild(LevelBuilder.makePickup(from: pickupDescriptor))
        }
        addChild(LevelBuilder.makePortal(at: configuration.portal))

        // TEMP: тестовая лестница для проверки механики.
        // В Шаге 6 перенесём в LevelConfiguration.
        let ladder = Ladder(size: CGSize(width: 32, height: 200))
        ladder.position = CGPoint(x: 320, y: 140)
        addChild(ladder)
    }

    // MARK: - Игровой цикл

    override func update(_ currentTime: TimeInterval) {
        lastUpdateTime = currentTime
        player.update()

        for child in children {
            if let levelObject = child as? LevelObject {
                levelObject.update(at: currentTime)
            }
        }

        applyLadderAction(ladderController.update())

        if jumpController.consumeJumpIfPossible(at: currentTime) {
            player.jump()
        }

        updateCamera()
    }

    private func applyLadderAction(_ action: LadderAction) {
        switch action {
        case .startClimbing:
            playerState.locomotionMode = .climbing
            player.physicsBody?.affectedByGravity = false
            player.physicsBody?.velocity = .zero
            player.enableClimbingMode()
            // Прилипаем к центру лестницы по X.
            if let ladder = currentLadder {
                player.position.x = ladder.position.x
            }

        case .climb(let verticalVelocity):
            let currentVx = player.physicsBody?.velocity.dx ?? 0
            player.physicsBody?.velocity = CGVector(dx: currentVx, dy: verticalVelocity)

        case .releaseLadder:
            playerState.locomotionMode = .normal
            player.physicsBody?.affectedByGravity = true
            player.disableClimbingMode()     // ← добавили

        case .idle:
            break
        }
    }

    private func updateCamera() {
        let halfW = size.width / 2
        let halfH = size.height / 2
        let targetX = max(halfW, min(configuration.levelWidth - halfW, player.position.x))
        let targetY = max(halfH, min(configuration.levelHeight - halfH, player.position.y))
        cameraNode.position = CGPoint(x: targetX, y: targetY)
    }

    // MARK: - Обработка событий

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
        let newScene = GameScene(configuration: configuration, progress: progress)
        newScene.scaleMode = scaleMode
        view?.presentScene(newScene, transition: .fade(withDuration: 0.5))
    }

    private func completeLevel() {
        let newProgress = GameProgressRules.levelCompleted(
            progress: progress,
            finalState: playerState
        )

        if GameProgressRules.isGameCompleted(progress: newProgress, totalLevels: Levels.all.count) {
            presentVictory(progress: newProgress)
        } else {
            let nextLevel = Levels.all[newProgress.currentLevelIndex]
            let newScene = GameScene(configuration: nextLevel, progress: newProgress)
            newScene.scaleMode = scaleMode
            view?.presentScene(newScene, transition: .fade(withDuration: 0.5))
        }
    }

    private func presentVictory(progress: GameProgress) {
        let victoryScene = VictoryScene(size: size, totalBonusPoints: progress.carriedBonusPoints)
        victoryScene.scaleMode = scaleMode
        view?.presentScene(victoryScene, transition: .fade(withDuration: 0.5))
    }
}

// MARK: - Делегаты

extension GameScene: InputControllerDelegate {

    func inputControllerDidPressLeft(_ controller: InputController) {
        player.startMovingLeft()
    }

    func inputControllerDidPressRight(_ controller: InputController) {
        player.startMovingRight()
    }

    func inputControllerDidReleaseHorizontal(_ controller: InputController) {
        player.stopMoving()
    }

    func inputControllerDidPressJump(_ controller: InputController) {
        if playerState.locomotionMode == .climbing {
            ladderController.didJumpOffLadder()
            jumpController.didReleaseLadder(at: lastUpdateTime)
            playerState.locomotionMode = .normal
            player.physicsBody?.affectedByGravity = true
            player.disableClimbingMode()     // ← добавили
        }
        jumpController.didPressJump(at: lastUpdateTime)
    }

    func inputControllerDidPressUp(_ controller: InputController) {
        ladderController.didPressUp()
    }

    func inputControllerDidPressDown(_ controller: InputController) {
        ladderController.didPressDown()
    }

    func inputControllerDidReleaseVertical(_ controller: InputController) {
        ladderController.didReleaseVertical()
    }
}


extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = (contact.bodyA, contact.bodyB)

        // Контакт игрока с землёй или платформой — обновляем jumpController.
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ground)
            || matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.platform) {
            jumpController.didTouchGround(at: lastUpdateTime)
            return
        }

        // Контакт игрока с лестницей — обновляем ladderController.
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ladder) {
            if let ladderBody = bodyOfCategory(PhysicsCategory.ladder, in: bodies),
               let ladder = ladderBody.node as? Ladder {
                currentLadder = ladder
            }
            ladderController.didTouchLadder()
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

        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ground)
            || matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.platform) {
            jumpController.didLeaveGround(at: lastUpdateTime)
        }

        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ladder) {
            currentLadder = nil
            ladderController.didLeaveLadder()
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
