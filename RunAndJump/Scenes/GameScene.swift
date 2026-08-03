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
    private var invulnerabilityController = InvulnerabilityController()
    private var platformRideController = PlatformRideController()
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Узлы

    private var player: Player!
    private var ground: SKSpriteNode!
    private var inputController: InputController!
    private let gamepadInput = GamepadInput()
    private var hud: HUDNode!
    private var cameraNode: SKCameraNode!
    private var movingPlatforms: [MovingPlatform] = []
    // Враги, умеющие стрелять. Держим отдельным списком, чтобы каждый кадр
    // не перебирать всех детей сцены ради нескольких стрелков.
    private var shooters: [Enemy] = []
    // Подвижная платформа, на которой сейчас стоит игрок; nil = не на подвижной платформе.
    private var playerStandingPlatform: MovingPlatform?
    // Опоры (земля + платформы), которых игрок касается прямо сейчас. Сообщаем
    // jumpController об отрыве от земли только когда исчезла последняя опора —
    // иначе платформа, прошедшая сквозь стоящего на земле игрока, ложно снимает
    // приземление и прыжок пропадает навсегда (см. GroundContactTracker).
    private var groundContacts = GroundContactTracker<ObjectIdentifier>()
    // Лестница, в зоне которой сейчас игрок — нужна, чтобы встать по её центру.
    private weak var currentLadder: Ladder?
    // Опасные зоны (озёра), в которых игрок находится прямо сейчас. Список, а не
    // одна ссылка: озёра могут соприкасаться, и выход из одного не должен
    // отменять пребывание в другом. Урон наносит последняя — та, куда вошли.
    private var occupiedHazards: [Hazard] = []

    // Длительность последнего кадра — нужна, чтобы ввод сдвигал игрока по платформе.
    private var previousUpdateTime: TimeInterval = 0
    private var frameDuration: TimeInterval = 0


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
        backgroundColor = ScenePalette.sky

        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        physicsWorld.contactDelegate = self

        view.isMultipleTouchEnabled = true

        setupCamera()
        setupGround()
        setupBoundaries()
        setupPlayer()
        setupInputController()
        setupGamepadInput()
        setupHUD()
        setupLevelObjects()
    }

    override func willMove(from view: SKView) {
        gamepadInput.stopObserving()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        updateCameraZoom()
    }

    // MARK: - Setup

    private func setupCamera() {
        cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        // Зум во время init пропускается (камеры ещё нет) — выставляем его здесь.
        updateCameraZoom()
    }

    private func setupGround() {
        let groundSize = CGSize(width: configuration.levelWidth, height: configuration.groundHeight)
        // Земля прозрачна: её внешний вид даёт травяное покрытие, а сам узел
        // несёт только физическое тело для коллизий.
        ground = SKSpriteNode(color: .clear, size: groundSize)
        ground.position = CGPoint(x: configuration.levelWidth / 2, y: groundSize.height / 2)

        let body = SKPhysicsBody(rectangleOf: groundSize)
        body.isDynamic = false
        // Без упругости: SpriteKit берёт max(restitution) двух тел, и дефолтные
        // 0.2 у опоры подбрасывали бы стоящего игрока (микро-баунс).
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.ground
        // Земля сама ни с кем не "ищет" контактов — её роль пассивная.
        body.contactTestBitMask = PhysicsCategory.none
        ground.physicsBody = body

        addChild(ground)

        // Покрываем землю травой — ряд тайлов по всей ширине уровня.
        for tile in LevelBuilder.makeGroundCover(widthInTiles: Int(configuration.levelWidthInTiles)) {
            addChild(tile)
        }
    }

    private func setupBoundaries() {
        let wallThickness: CGFloat = 4
        let wallHeight = configuration.levelHeight

        for xPos in [wallThickness / 2, configuration.levelWidth - wallThickness / 2] {
            let wall = SKSpriteNode(color: .clear, size: CGSize(width: wallThickness, height: wallHeight))
            wall.position = CGPoint(x: xPos, y: wallHeight / 2)
            let body = SKPhysicsBody(rectangleOf: wall.size)
            body.isDynamic = false
            body.restitution = 0
            body.categoryBitMask = PhysicsCategory.wall
            body.contactTestBitMask = PhysicsCategory.none
            wall.physicsBody = body
            addChild(wall)
        }
    }

    private func setupPlayer() {
        player = Player()
        player.position = Grid.center(origin: configuration.playerStart, size: ObjectSize.player)
        addChild(player)
    }

    private func setupInputController() {
        inputController = InputController(sceneSize: size)
        inputController.delegate = self
        // Кнопки расположены относительно левого нижнего угла — смещаем узел туда.
        inputController.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        cameraNode.addChild(inputController)
    }

    private func setupGamepadInput() {
        gamepadInput.delegate = self
        // Пока геймпад подключён — экранные кнопки лишние, прячем их.
        gamepadInput.onConnectionChange = { [weak self] connected in
            self?.inputController.setControlsHidden(connected)
        }
        gamepadInput.startObserving()
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
            // Нижний-левый угол прямоугольника на сетке прямо ложится в origin CGRect.
            platformRideController.obstacles.append(CGRect(
                origin: Grid.point(platformDescriptor.rect.origin),
                size: Grid.size(platformDescriptor.rect.size)
            ))
        }
        for descriptor in configuration.movingPlatforms {
            let platform = LevelBuilder.makeMovingPlatform(from: descriptor)
            addChild(platform)
            movingPlatforms.append(platform)
        }
        for enemyDescriptor in configuration.enemies {
            let enemy = LevelBuilder.makeEnemy(from: enemyDescriptor)
            addChild(enemy)
            if enemy.canShoot {
                shooters.append(enemy)
            }
        }
        for pickupDescriptor in configuration.pickups {
            addChild(LevelBuilder.makePickup(from: pickupDescriptor))
        }
        for ladderDescriptor in configuration.ladders {
            addChild(LevelBuilder.makeLadder(from: ladderDescriptor))
        }
        for hazardDescriptor in configuration.hazards {
            addChild(LevelBuilder.makeHazard(from: hazardDescriptor))
        }
        for decorationDescriptor in configuration.decorations {
            addChild(LevelBuilder.makeDecoration(from: decorationDescriptor))
        }
        addChild(LevelBuilder.makePortal(from: configuration.portal))
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
        player.updateAnimation(isOnGround: jumpController.isGrounded)

        // Обновляем все игровые объекты с поведением (враги и т. п.).
        for child in children {
            if let levelObject = child as? LevelObject {
                levelObject.update(at: currentTime)
            }
        }

        updateShooters(at: currentTime)
        updateHazards()

        let playerFeetY = player.position.y - player.size.height / 2
        applyLadderAction(ladderController.update(playerFeetY: playerFeetY))

        if jumpController.consumeJumpIfPossible(at: currentTime) {
            player.jump()
            // Прыжок отрывает игрока от платформы — снимаем привязку и запускаем кулдаун,
            // чтобы поднимающаяся платформа не зацепила взлетающего игрока сразу же.
            playerStandingPlatform = nil
            platformRideController.didJump(at: currentTime)
        }

        updateCamera()
    }

    // Перенос игрока вместе с платформой делаем ПОСЛЕ физики, иначе солвер откатывает
    // ручное смещение позиции и игрок отстаёт от платформы (сползает с неё).
    override func didSimulatePhysics() {
        guard let platform = playerStandingPlatform, let body = player.physicsBody else { return }

        let action = platformRideController.resolveRide(
            platformPosition: platform.position,
            platformSize: platform.size,
            playerPosition: player.position,
            playerSize: player.size,
            horizontalInputVelocity: player.hasHorizontalInput ? player.horizontalVelocity : 0,
            dt: frameDuration
        )

        switch action {
        case .ride(let target):
            player.position = target
            // Пока едем на платформе — гасим накопление гравитации, чтобы прыжок был чистым.
            body.velocity.dy = 0

        case .idle:
            // Контроллер сам решил, что езда кончилась (игрока снесло за край) —
            // отпускаем хэндл, не дожидаясь didEnd от физики.
            playerStandingPlatform = nil
        }
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
            // На лестнице горизонтальное отклонение стика игнорируем: гасим
            // боковую скорость и каждый кадр держим игрока строго по центру
            // лестницы. Иначе невыводимый «дрейф» джойстика сносит его вбок,
            // и он срывается с лестницы. Спрыгнуть посреди лестницы можно
            // только кнопкой прыжка (см. inputDidPressJump).
            player.physicsBody?.velocity = CGVector(dx: 0, dy: verticalVelocity)
            if let ladder = currentLadder {
                player.position.x = ladder.position.x
            }

        case .releaseLadder:
            playerState.locomotionMode = .normal
            player.physicsBody?.affectedByGravity = true
            player.disableClimbingMode()
            // Если отпустили, всё ещё касаясь лестницы — значит дошли до её
            // основания. Ставим ступни ровно на опору (землю или платформу) и
            // гасим вертикальную скорость, чтобы не провалиться сквозь платформу,
            // через которую в режиме лазания проходили. При сходе сверху
            // currentLadder уже nil (контакт потерян) — там доводит гравитация.
            if let ladder = currentLadder {
                player.position.y = ladderBottomY(of: ladder) + player.size.height / 2
                player.physicsBody?.velocity.dy = 0
            }

        case .idle:
            break
        }
    }

    /// Y нижнего края лестницы — её основание (верх земли или платформы, на
    /// которой она стоит).
    private func ladderBottomY(of ladder: Ladder) -> CGFloat {
        ladder.position.y - ladder.size.height / 2
    }

    /// Даёт стрелкам сделать выстрел. Решение — за врагом (и чистой моделью
    /// внутри него), создание узла — за сценой: иерархией владеет она.
    private func updateShooters(at time: TimeInterval) {
        // Повержённый стрелок уже покинул сцену — отпускаем и последнюю ссылку.
        shooters.removeAll { $0.isDefeated }

        for shooter in shooters {
            guard let spawn = shooter.updateShooting(at: time,
                                                     targetPosition: player.position) else { continue }
            addChild(LevelBuilder.makeProjectile(from: spawn))
        }
    }

    // MARK: - Камера

    private func updateCamera() {
        // Видимая область камеры = размер сцены, умноженный на её масштаб (зум).
        // Клэмп считаем по ней, иначе при scale != 1 по краям уровня видна пустота.
        let scale = cameraNode.yScale
        let viewportSize = CGSize(width: size.width * scale, height: size.height * scale)
        let levelSize = CGSize(width: configuration.levelWidth, height: configuration.levelHeight)
        cameraNode.position = CameraMath.clampedPosition(target: player.position, viewportSize: viewportSize, levelSize: levelSize)
    }

    private func updateCameraZoom() {
        // didChangeSize прилетает уже из super.init(size:) — до setupCamera, когда
        // камеры ещё нет. Поэтому идём через optional camera, а не cameraNode!.
        // Плюс на раннем layout-проходе size может быть нулевым — деление дало бы inf.
        guard let camera, size.height > 0 else { return }
        let visibleWorldHeight = WorldMetrics.visibleTilesTall * WorldMetrics.tileSize
        camera.setScale(visibleWorldHeight / size.height)
    }

    // MARK: - Обработка событий

    /// Разбирает касание врага: прыжок сверху убивает врага, всё остальное — урон.
    /// Само правило чистое (`EnemyContactRules`), сцена лишь подставляет геометрию.
    private func handleEnemyContact(with enemy: Enemy) {
        // Поверженный враг уже не опасен: контакт с ним мог прийти в том же кадре,
        // пока его физическое тело ещё не снято (снимается после шага симуляции).
        guard !enemy.isDefeated else { return }

        let outcome = EnemyContactRules.outcome(
            playerBottom: player.position.y - player.size.height / 2,
            playerVelocityY: player.physicsBody?.velocity.dy ?? 0,
            enemyTop: enemy.position.y + enemy.size.height / 2,
            enemyHeight: enemy.size.height
        )

        switch outcome {
        case .stomp:
            enemy.defeat()
            player.bounceOffEnemy()
            // Маппинг «вид врага → очки» живёт в модели и покрыт тестами.
            handle(enemy.kind.defeatEvent)
        case .damage:
            applyDamage(.enemyHit)
        }
    }

    /// Наносит игроку урон с учётом окна неуязвимости — общий путь для всех
    /// источников (враг, снаряд, опасная зона). `recovery` — длина окна:
    /// у озера она своя, чтобы стоящего в лаве жгло чаще, чем в воде.
    private func applyDamage(
        _ event: GameEvent,
        recovery: TimeInterval = InvulnerabilityController.damageRecoveryDuration
    ) {
        // Пока действует неуязвимость — урон игнорируется.
        guard !invulnerabilityController.isInvulnerable(at: lastUpdateTime) else { return }

        handle(event)

        // Если удар не смертельный — даём окно неуязвимости и запускаем мерцание.
        // При смертельном ударе сцена перезапускается, индикация не нужна.
        guard !GameRules.isDead(playerState) else { return }
        invulnerabilityController.trigger(for: recovery, at: lastUpdateTime)
        player.startBlinking(for: recovery)
    }

    /// Пока игрок в озере, оно бьёт его снова и снова — паузу между ударами
    /// задаёт вид зоны. Проверяем каждый кадр, а не только по входу: важно
    /// именно нахождение в зоне, а не момент пересечения границы.
    private func updateHazards() {
        // В озере игрок утоплен по пояс — иначе кажется, что он идёт по воде.
        // Глубина зависит от того, насколько он зашёл: шагая по кромке, он
        // опускается и всплывает плавно, а не проваливается рывком.
        player.setSubmersion(hazardImmersionDepth())

        guard let hazard = occupiedHazards.last else { return }
        applyDamage(hazard.kind.event, recovery: hazard.kind.damageInterval)
    }

    /// Погружение по самой «глубокой» из зон, которых игрок сейчас касается.
    /// Геометрию считает модель, сцена лишь подставляет габариты узлов.
    private func hazardImmersionDepth() -> CGFloat {
        let playerSpan = span(of: player.position.x, width: player.size.width)
        return occupiedHazards.reduce(0) { deepest, hazard in
            let hazardSpan = span(of: hazard.position.x, width: hazard.size.width)
            return max(deepest, HazardImmersion.depth(player: playerSpan, hazard: hazardSpan))
        }
    }

    private func span(of centerX: CGFloat, width: CGFloat) -> ClosedRange<CGFloat> {
        (centerX - width / 2)...(centerX + width / 2)
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

extension GameScene: GameInputDelegate {

    func inputDidUpdateDirection(horizontal: CGFloat, vertical: CGFloat) {
        // Горизонталь — аналоговая скорость персонажа; вертикаль — лазание по лестнице.
        player.setHorizontalInput(horizontal)
        ladderController.setVerticalInput(vertical)
    }

    func inputDidPressJump() {
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

        // Контакт снаряда: с игроком — урон, с геометрией уровня — просто гаснет.
        if let projectileBody = bodyOfCategory(PhysicsCategory.projectile, in: bodies),
           let projectile = projectileBody.node as? Projectile {
            // Один снаряд бьёт один раз: за шаг симуляции контакт может прийти
            // и от игрока, и от платформы, а тело снимается только после шага.
            guard !projectile.isSpent else { return }

            let other = projectileBody === bodies.0 ? bodies.1 : bodies.0
            if other.categoryBitMask == PhysicsCategory.player {
                applyDamage(.enemyHit)
            }
            projectile.hit()
            return
        }

        // Контакт игрока с землёй или платформой — обновляем jumpController.
        if let supportBody = supportingBody(in: bodies) {
            groundContacts.add(ObjectIdentifier(supportBody))
            jumpController.didTouchGround(at: lastUpdateTime)
            if let movingPlatform = supportBody.node as? MovingPlatform {
                let attached = platformRideController.tryAttach(
                    platformPosition: movingPlatform.position,
                    platformSize: movingPlatform.size,
                    playerPosition: player.position,
                    playerSize: player.size,
                    at: lastUpdateTime
                )
                if attached {
                    playerStandingPlatform = movingPlatform
                }
            }
            return
        }

        // Контакт игрока с лестницей — обновляем ladderController.
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ladder) {
            if let ladderBody = bodyOfCategory(PhysicsCategory.ladder, in: bodies),
               let ladder = ladderBody.node as? Ladder {
                currentLadder = ladder
                ladderController.didTouchLadder(bottomY: ladderBottomY(of: ladder))
            }
            return
        }

        // Контакт игрока с опасной зоной — запоминаем, что он в ней. Сам урон
        // наносится в игровом цикле, пока игрок не вышел (см. updateHazardDamage).
        if let hazardBody = bodyOfCategory(PhysicsCategory.hazard, in: bodies),
           let hazard = hazardBody.node as? Hazard {
            occupiedHazards.append(hazard)
            return
        }

        // Контакт игрока с врагом.
        if let enemyBody = bodyOfCategory(PhysicsCategory.enemy, in: bodies),
           let enemy = enemyBody.node as? Enemy {
            handleEnemyContact(with: enemy)
            return
        }

        // Контакт игрока с подбираемой наградой.
        if let pickupBody = bodyOfCategory(PhysicsCategory.pickup, in: bodies), let pickup = pickupBody.node as? Pickup {
            // Сцена не разбирает виды наград: маппинг «вид → событие»
            // живёт в модели (PickupKind.event) и покрыт тестами.
            handle(pickup.kind.event)
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

        if let supportBody = supportingBody(in: bodies) {
            // Уходим с земли только когда исчезла ПОСЛЕДНЯЯ опора — иначе платформа,
            // прошедшая сквозь стоящего на земле игрока, ложно «снимает» приземление.
            if groundContacts.remove(ObjectIdentifier(supportBody)) {
                jumpController.didLeaveGround(at: lastUpdateTime)
            }
            if supportBody.node is MovingPlatform {
                playerStandingPlatform = nil
                platformRideController.didLeavePlatform()
            }
            return
        }

        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ladder) {
            currentLadder = nil
            ladderController.didLeaveLadder()
            return
        }

        // Игрок выбрался из озера — снимаем ровно одно вхождение.
        if let hazardBody = bodyOfCategory(PhysicsCategory.hazard, in: bodies),
           let hazard = hazardBody.node as? Hazard,
           let index = occupiedHazards.firstIndex(where: { $0 === hazard }) {
            occupiedHazards.remove(at: index)
        }
    }

    // MARK: - Helpers

    /// Проверяют, что в контакте участвуют две заявленных категории.
    private func matchesPair(_ bodies: (SKPhysicsBody, SKPhysicsBody), _ a: UInt32, _ b: UInt32) -> Bool {
        let combined = bodies.0.categoryBitMask | bodies.1.categoryBitMask
        return combined == (a | b)
    }

    /// Тело-опора (земля или платформа) в контакте с игроком, иначе nil.
    /// Опоры держат `supportingContacts` — состояние «игрок на земле».
    private func supportingBody(in bodies: (SKPhysicsBody, SKPhysicsBody)) -> SKPhysicsBody? {
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.ground) {
            return bodyOfCategory(PhysicsCategory.ground, in: bodies)
        }
        if matchesPair(bodies, PhysicsCategory.player, PhysicsCategory.platform) {
            return bodyOfCategory(PhysicsCategory.platform, in: bodies)
        }
        return nil
    }

    /// Находит тело заданной категории, чтобы достать его узел.
    private func bodyOfCategory(_ category: UInt32, in bodies: (SKPhysicsBody, SKPhysicsBody)) -> SKPhysicsBody? {
        if bodies.0.categoryBitMask == category { return bodies.0 }
        if bodies.1.categoryBitMask == category { return bodies.1 }
        return nil
    }
}
