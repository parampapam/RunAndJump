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
    private var movingPlatforms: [MovingPlatform] = []
    // Подвижная платформа, на которой сейчас стоит игрок; nil = не на подвижной платформе.
    private var playerStandingPlatform: MovingPlatform?
    // Лестница, в зоне которой сейчас игрок — нужна, чтобы встать по её центру.
    private weak var currentLadder: Ladder?

    // Сплошные рамки неподвижных платформ — преграды при переносе игрока подвижной платформой.
    private var staticPlatformFrames: [CGRect] = []
    // Смещение игрока относительно центра платформы — фиксирует его в системе отсчёта платформы.
    private var platformRideOffset: CGPoint = .zero
    // Длительность последнего кадра — нужна, чтобы ввод сдвигал игрока по платформе.
    private var previousUpdateTime: TimeInterval = 0
    private var frameDuration: TimeInterval = 0
    // Время последнего прыжка — после него короткий запрет на привязку к платформе.
    private var lastJumpTime: TimeInterval = -1000
    private let attachCooldownAfterJump: TimeInterval = 0.25


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
            // Запоминаем сплошные рамки — об них упирается игрок при езде на подвижной платформе.
            staticPlatformFrames.append(CGRect(
                x: platformDescriptor.position.x - platformDescriptor.size.width / 2,
                y: platformDescriptor.position.y - platformDescriptor.size.height / 2,
                width: platformDescriptor.size.width,
                height: platformDescriptor.size.height
            ))
        }
        for descriptor in configuration.movingPlatforms {
            let platform = LevelBuilder.makeMovingPlatform(from: descriptor)
            addChild(platform)
            movingPlatforms.append(platform)
        }
        for enemyDescriptor in configuration.enemies {
            addChild(LevelBuilder.makeEnemy(from: enemyDescriptor))
        }
        for pickupDescriptor in configuration.pickups {
            addChild(LevelBuilder.makePickup(from: pickupDescriptor))
        }
        for ladderDescriptor in configuration.ladders {
            addChild(LevelBuilder.makeLadder(from: ladderDescriptor))
        }
        addChild(LevelBuilder.makePortal(at: configuration.portal))
    }

    // MARK: - Игровой цикл

    override func update(_ currentTime: TimeInterval) {
        frameDuration = previousUpdateTime == 0 ? 0 : currentTime - previousUpdateTime
        previousUpdateTime = currentTime
        lastUpdateTime = currentTime

        // Двигаем платформы до физического шага, чтобы их рёбра были на новом месте.
        for platform in movingPlatforms {
            platform.update(at: currentTime)
        }

        player.update()

        // Обновляем все игровые объекты с поведением (враги и т. п.).
        for child in children {
            if let levelObject = child as? LevelObject {
                levelObject.update(at: currentTime)
            }
        }

        applyLadderAction(ladderController.update())

        if jumpController.consumeJumpIfPossible(at: currentTime) {
            player.jump()
            // Прыжок отрывает игрока от платформы — снимаем привязку и запускаем кулдаун,
            // чтобы поднимающаяся платформа не зацепила взлетающего игрока сразу же.
            playerStandingPlatform = nil
            lastJumpTime = currentTime
        }

        updateCamera()
    }

    // Привязку игрока к платформе делаем ПОСЛЕ физики, иначе солвер откатывает
    // ручное смещение позиции и игрок отстаёт от платформы (сползает с неё).
    override func didSimulatePhysics() {
        guard let platform = playerStandingPlatform, let body = player.physicsBody else { return }

        // Ввод игрока смещает его в системе отсчёта платформы — движение аддитивно к ходу платформы.
        if player.hasHorizontalInput {
            platformRideOffset.x += player.horizontalVelocity * CGFloat(frameDuration)
        }

        var target = CGPoint(
            x: platform.position.x + platformRideOffset.x,
            y: platform.position.y + platformRideOffset.y
        )
        // Неподвижная платформа на пути не даёт пронести игрока сквозь себя — упираемся в её бок.
        target.x = blockedCarryX(target: target, currentX: player.position.x)
        // Возвращаем смещение к фактическому X: иначе ввод копится «за преградой», и когда
        // target.x уедет за край статичной платформы, ограничение спадёт и игрока выстрелит вперёд.
        platformRideOffset.x = target.x - platform.position.x
        player.position = target

        // Пока стоим на платформе — гасим накопление гравитации, чтобы прыжок был чистым.
        body.velocity.dy = 0
    }

    /// Привязывает игрока к подвижной платформе, только если он действительно приземлился
    /// на неё СВЕРХУ (низ игрока у верхнего ребра). При ударе снизу низ игрока намного ниже
    /// ребра — привязки нет, физика отрабатывает отскок. Сразу после прыжка привязка
    /// запрещена кулдауном, чтобы поднимающаяся платформа не зацепила взлетающего игрока.
    private func tryAttach(to movingPlatform: MovingPlatform) {
        guard lastUpdateTime - lastJumpTime > attachCooldownAfterJump else { return }

        let platformTop = movingPlatform.position.y + movingPlatform.size.height / 2
        let playerBottom = player.position.y - player.size.height / 2
        let landingTolerance: CGFloat = 10
        guard playerBottom >= platformTop - landingTolerance else { return }

        playerStandingPlatform = movingPlatform
        // X — где игрок встал вдоль платформы; Y — высота покоя над её верхним ребром.
        platformRideOffset = CGPoint(
            x: player.position.x - movingPlatform.position.x,
            y: movingPlatform.size.height / 2 + player.size.height / 2
        )
    }

    /// Ограничивает горизонтальный перенос игрока подвижной платформой, если на пути
    /// оказался бок неподвижной платформы. Возвращает допустимый X.
    private func blockedCarryX(target: CGPoint, currentX: CGFloat) -> CGFloat {
        let movingRight = target.x > currentX
        let movingLeft = target.x < currentX
        guard movingRight || movingLeft else { return target.x }

        let halfW = player.size.width / 2
        let halfH = player.size.height / 2
        let epsilon: CGFloat = 1
        let top = target.y + halfH
        let bottom = target.y - halfH

        var resultX = target.x
        for frame in staticPlatformFrames {
            // Только боковое перекрытие: если игрок стоит на верхнем ребре — не преграда.
            guard bottom < frame.maxY - epsilon, top > frame.minY + epsilon else { continue }
            guard resultX + halfW > frame.minX, resultX - halfW < frame.maxX else { continue }
            if movingRight {
                resultX = min(resultX, frame.minX - halfW)
            } else {
                resultX = max(resultX, frame.maxX + halfW)
            }
        }
        return resultX
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

    func inputControllerDidPressUp(_ controller: InputController) {
        ladderController.didPressUp()
    }

    func inputControllerDidPressDown(_ controller: InputController) {
        ladderController.didPressDown()
    }

    func inputControllerDidReleaseHorizontal(_ controller: InputController) {
        player.stopMoving()
    }

    func inputControllerDidReleaseVertical(_ controller: InputController) {
        ladderController.didReleaseVertical()
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
}


extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = (contact.bodyA, contact.bodyB)

        // Контакт игрока с землёй или платформой — обновляем jumpController.
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ground)
            || matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.platform) {
            jumpController.didTouchGround(at: lastUpdateTime)
            if let platformBody = bodyOfCategory(PhysicsCategory.platform, in: bodies),
               let movingPlatform = platformBody.node as? MovingPlatform {
                tryAttach(to: movingPlatform)
            }
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
            if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.platform),
               let platformBody = bodyOfCategory(PhysicsCategory.platform, in: bodies),
               platformBody.node is MovingPlatform {
                playerStandingPlatform = nil
            }
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
