//
//  GameScene.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit
// UIKit — явно: в проекте включён MEMBER_IMPORT_VISIBILITY, и уведомления
// жизненного цикла приложения не видны через реэкспорт из SpriteKit.
import UIKit

final class GameScene: SKScene {

    // MARK: - Конфигурация и состояние

    private let configuration: LevelConfiguration
    // var, а не let: пройденный флаг меняет точку восстановления, и это
    // единственное состояние, которое переживает гибель — сцена пересоздаётся
    // с тем же `progress`.
    private var progress: GameProgress
    // Куда прогресс уходит, чтобы пережить выгрузку приложения из памяти.
    // Инжектируется и передаётся дальше при пересоздании сцены.
    private let progressStore: any GameProgressStore

    private var playerState: PlayerState
    private var jumpController = JumpController()
    private var ladderController = LadderController()
    private var invulnerabilityController = InvulnerabilityController()
    private var platformRideController = PlatformRideController()
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Узлы

    /// Сборщик узлов уровня вместе с темой — чем нарисован этот стиль.
    /// Создаётся один раз в `init` по `configuration.style` и живёт со сценой:
    /// пересоздание сцены (гибель, следующий уровень) собирает тему заново.
    private let builder: LevelBuilder

    private var player: Player!
    private var inputController: InputController!
    private let gamepadInput = GamepadInput()
    private var hud: HUDNode!
    private var cameraNode: SKCameraNode!
    private var background: Background!
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
    // Флаги точек восстановления уровня. Держим список, чтобы при подъёме
    // одного опустить остальные.
    private var checkpoints: [Checkpoint] = []
    // Враги, побеждённые с последнего флага. Живёт в сцене и вместе с ней
    // умирает — в этом и смысл: при гибели эти враги возвращаются на уровень,
    // а очки за них снимаются. Флаг переносит их в `progress`, засчитывая
    // победу окончательно.
    private var defeatedSinceCheckpoint: Set<Int> = []

    // Открытое окно паузы; nil — игра идёт. Оно же и есть признак паузы:
    // держать отдельный флаг рядом с узлом значило бы держать одно состояние
    // в двух местах.
    private var pauseMenu: PauseMenuNode?
    private var isGamePaused: Bool { pauseMenu != nil }
    /// Подписки на сворачивание приложения; снимаются вместе со сценой.
    private var lifecycleObservers: [NSObjectProtocol] = []

    // Длительность последнего кадра — нужна, чтобы ввод сдвигал игрока по платформе.
    // Через FrameClock, а не вычитанием вручную: он же ограничивает дельту
    // сверху, и первый кадр после разворачивания приложения не швыряет игрока
    // через полуровня (см. FrameClock).
    private var frameClock = FrameClock()
    private var frameDuration: TimeInterval = 0


    // MARK: - Init

    init(configuration: LevelConfiguration,
         progress: GameProgress,
         store: any GameProgressStore) {
        self.configuration = configuration
        self.progress = progress
        self.progressStore = store
        self.playerState = GameProgressRules.initialPlayerState(for: progress)
        self.builder = LevelBuilder(
            textures: LevelTextures(catalog: StyleCatalogs.resolved(configuration.style))
        )
        super.init(size: configuration.sceneSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Жизненный цикл

    override func didMove(to view: SKView) {
        // Цвет неба берётся из стиля и совпадает с заливкой фона: он виден на
        // дне ям под озёрами, где за жидкостью нет грунта.
        backgroundColor = builder.textures.skyColor

        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        physicsWorld.contactDelegate = self

        view.isMultipleTouchEnabled = true

        setupCamera()
        setupBackground()
        setupGround()
        setupBoundaries()
        setupPlayer()
        setupInputController()
        setupGamepadInput()
        setupHUD()
        setupLevelObjects()

        startObservingAppLifecycle()
    }

    override func willMove(from view: SKView) {
        gamepadInput.stopObserving()
        stopObservingAppLifecycle()
    }

    /// Свёрнутое приложение ставит игру на паузу само.
    ///
    /// Подписываемся здесь, а не в SwiftUI: `GameHost` держит только **первую**
    /// сцену, дальше `GameScene` пересоздаёт себя сама через `presentScene`, и
    /// ссылка снаружи указывала бы на давно выброшенную сцену. Каждая сцена
    /// живёт со своей подпиской ровно столько, сколько показана.
    ///
    /// `willResignActive`, а не `didEnterBackground`: шторка уведомлений,
    /// переключатель приложений и входящий звонок оставляют игру видимой и
    /// живой, хотя управлять ею уже нельзя, — а это потерянная жизнь.
    private func startObservingAppLifecycle() {
        let observer = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.presentPauseMenu()
            }
        }
        lifecycleObservers.append(observer)
    }

    private func stopObservingAppLifecycle() {
        lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
        lifecycleObservers.removeAll()
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

    /// Фон ставится сразу после камеры: его полосы едут за ней, и первый кадр
    /// должен застать их уже на месте.
    private func setupBackground() {
        background = builder.makeBackground(from: configuration)
        addChild(background)
        updateBackground()
    }

    /// Земля — не сплошная полоса, а куски между проёмами под озёрами: озеро
    /// должно быть настоящей ямой, в которую игрок проваливается. Границы
    /// кусков считает чистый `GroundLayout`, дно ям кладём отдельными опорами.
    private func setupGround() {
        let segments = GroundLayout.segments(
            levelWidthInTiles: configuration.levelWidthInTiles,
            gaps: configuration.hazards.map { $0.rect.xSpan }
        )

        for segment in segments {
            addChild(builder.makeGround(span: segment, height: configuration.groundHeight))
            // Покрываем кусок травой — она же и есть видимая земля.
            for tile in builder.makeGroundCover(span: segment) {
                addChild(tile)
            }
        }

        for hazardDescriptor in configuration.hazards {
            addChild(builder.makeHazardFloor(from: hazardDescriptor,
                                                  groundHeight: configuration.groundHeight))
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

    /// Игрок появляется у последней пройденной точки восстановления, а до
    /// первого флага — на старте уровня. Выбор — за чистой моделью.
    private func setupPlayer() {
        let origin = CheckpointRules.respawnOrigin(
            checkpoints: configuration.checkpoints,
            levelStart: configuration.playerStart,
            activated: progress.activeCheckpointIndex
        )
        player = Player()
        player.position = Grid.center(origin: origin, size: ObjectSize.player)
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
        gamepadInput.onConnectionChange = { [weak self] _ in
            self?.updateControlsVisibility()
        }
        gamepadInput.startObserving()
    }

    /// Экранное управление видно, только когда игра идёт и физического геймпада
    /// нет. Единая точка решения: подключение геймпада приходит уведомлением в
    /// произвольный момент, и раздельные вызовы «спрятать/показать» затирали бы
    /// друг друга — открытое окно паузы теряло бы скрытые кнопки.
    private func updateControlsVisibility() {
        inputController.setControlsHidden(isGamePaused || gamepadInput.isConnected)
    }

    private func setupHUD() {
        hud = HUDNode(sceneSize: size)
        hud.update(with: playerState)
        hud.onPauseTapped = { [weak self] in
            self?.presentPauseMenu()
        }
        cameraNode.addChild(hud)
    }

    private func setupLevelObjects() {
        for platformDescriptor in configuration.platforms {
            addChild(builder.makePlatform(from: platformDescriptor))
            // Запоминаем сплошные рамки — об них упирается игрок при езде на подвижной платформе.
            // Нижний-левый угол прямоугольника на сетке прямо ложится в origin CGRect.
            platformRideController.obstacles.append(CGRect(
                origin: Grid.point(platformDescriptor.rect.origin),
                size: Grid.size(platformDescriptor.rect.size)
            ))
        }
        for descriptor in configuration.movingPlatforms {
            let platform = builder.makeMovingPlatform(from: descriptor)
            addChild(platform)
            movingPlatforms.append(platform)
        }
        // Враги, победа над которыми уже засчитана флагом, на уровень не
        // возвращаются. Побеждённые после флага — возвращаются (см. restartLevel).
        for (index, enemyDescriptor) in configuration.enemies.enumerated()
        where !progress.defeatedEnemyIndices.contains(index) {
            let enemy = builder.makeEnemy(from: enemyDescriptor, index: index)
            addChild(enemy)
            if enemy.canShoot {
                shooters.append(enemy)
            }
        }
        // Монеты, поднятые до гибели, на сцену не возвращаются: очки за них уже
        // сохранены. Аптечки в этот список не попадают и появляются снова.
        for (index, pickupDescriptor) in configuration.pickups.enumerated()
        where !progress.collectedPickupIndices.contains(index) {
            addChild(builder.makePickup(from: pickupDescriptor, index: index))
        }
        // Флаг активной точки восстановления поднят с самого начала — после
        // гибели игрок должен видеть, где именно он появился.
        for (index, checkpointDescriptor) in configuration.checkpoints.enumerated() {
            let checkpoint = builder.makeCheckpoint(
                from: checkpointDescriptor,
                index: index,
                state: CheckpointRules.state(of: index, active: progress.activeCheckpointIndex)
            )
            addChild(checkpoint)
            checkpoints.append(checkpoint)
        }
        for ladderDescriptor in configuration.ladders {
            addChild(builder.makeLadder(from: ladderDescriptor))
        }
        for hazardDescriptor in configuration.hazards {
            addChild(builder.makeHazard(from: hazardDescriptor))
        }
        for decorationDescriptor in configuration.decorations {
            // nil — декорации нет в каталоге стиля: пропускаем, уровень от
            // лишнего цветочка терять нельзя (см. `LevelBuilder.makeDecoration`).
            guard let decoration = builder.makeDecoration(from: decorationDescriptor) else { continue }
            addChild(decoration)
        }
        addChild(builder.makePortal(from: configuration.portal))
    }

    // MARK: - Игровой цикл

    override func update(_ currentTime: TimeInterval) {
        // На паузе игровой цикл не идёт. Часы кадров не трогаем — первый кадр
        // после паузы даст большую дельту, но FrameClock её ограничит.
        guard !isGamePaused else {
            // Сюда мы вообще попадаем, только если `isPaused` кто-то снял
            // снаружи: SKView делает это сам, когда приложение возвращается в
            // активное состояние. Игровой цикл это переживает (мы уже вышли),
            // а вот действия узлов — нет: враги под окном паузы снова замахали
            // бы лапами. Возвращаем паузу на место.
            setGameplayPaused(true)
            return
        }

        frameDuration = frameClock.tick(at: currentTime) ?? 0
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
            addChild(builder.makeProjectile(from: spawn))
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
        updateBackground()
    }

    /// Фон едет следом за камерой, поэтому обновляется **после** неё —
    /// иначе полосы отставали бы на кадр и заметно дёргались.
    private func updateBackground() {
        let tile = WorldMetrics.tileSize
        let scale = cameraNode.yScale
        background.update(
            viewportSizeInTiles: TileSize(width: size.width * scale / tile,
                                          height: size.height * scale / tile),
            cameraCenterInTiles: CGPoint(x: cameraNode.position.x / tile,
                                         y: cameraNode.position.y / tile)
        )
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
            // Победа засчитывается «в долг» — до ближайшего флага. Погибнув
            // раньше, игрок встретит этого врага снова, а очки за него потеряет.
            defeatedSinceCheckpoint.insert(enemy.index)
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
        guard let hazard = occupiedHazards.last else { return }
        applyDamage(hazard.kind.event, recovery: hazard.kind.damageInterval)
    }

    /// Игрок прошёл мимо флага: этот поднимается и становится текущей точкой
    /// восстановления, остальные опускаются. Повторный проход мимо уже
    /// поднятого флага — не событие (решает `CheckpointRules`).
    private func activateCheckpoint(_ checkpoint: Checkpoint) {
        let activation = CheckpointRules.activation(touched: checkpoint.index,
                                                    active: progress.activeCheckpointIndex)
        guard activation == .activate else { return }

        // Флаг засчитывает победы окончательно — и список «в долг» обнуляется,
        // иначе гибель сняла бы очки за врагов, которых уже не вернуть.
        progress = GameProgressRules.checkpointReached(
            progress: progress,
            index: checkpoint.index,
            defeatedSinceCheckpoint: defeatedSinceCheckpoint
        )
        defeatedSinceCheckpoint.removeAll()

        // Флаг — единственный момент внутри уровня, когда состояние
        // непротиворечиво: враги засчитаны, точка возрождения известна.
        // Поэтому сохраняемся именно здесь, а не по уходу в фон: свёрнутое
        // приложение выгружают без предупреждения.
        saveProgress()

        for flag in checkpoints {
            flag.setState(CheckpointRules.state(of: flag.index, active: checkpoint.index))
        }
    }

    /// Кладёт текущий прогресс в хранилище — вместе с очками, набранными прямо
    /// сейчас (склейку делает модель, см. `GameProgressRules.snapshot`).
    private func saveProgress() {
        progressStore.save(GameProgressRules.snapshot(progress: progress, state: playerState))
    }

    // MARK: - Пауза

    /// Открывает окно паузы и останавливает игру. Повторный вызов при уже
    /// открытом окне ничего не делает.
    private func presentPauseMenu() {
        guard pauseMenu == nil else { return }

        let menu = PauseMenuNode(sceneSize: size) { [weak self] action in
            self?.handle(pauseAction: action)
        }
        cameraNode.addChild(menu)
        pauseMenu = menu

        // Экранное управление под окном только мешает. Прячем — заодно
        // снимается удержание джойстика, иначе после снятия паузы игрок
        // побежал бы сам.
        updateControlsVisibility()
        setGameplayPaused(true)
    }

    private func handle(pauseAction action: PauseMenuAction) {
        switch action {
        case .resume:
            resumeGame()

        case .restartLevel:
            // Уровень собирается как при первом входе, а счёт откатывается
            // к очкам на входе — иначе перезапуск был бы фермой очков
            // (см. GameProgressRules.levelRestarted).
            let newProgress = GameProgressRules.levelRestarted(progress: progress)
            progressStore.save(newProgress)
            present(GameScene(configuration: configuration,
                              progress: newProgress,
                              store: progressStore))

        case .mainMenu:
            // Сохранение НЕ трогаем: выход в меню — это навигация, а не сброс
            // игры. Стереть его здесь значило бы уничтожить партию игрока за то,
            // что он открыл меню; начать партию заново он оттуда и так может.
            // Не сохраняем тоже: см. `PauseMenuAction.mainMenu`.
            present(MainMenuScene(store: progressStore))
        }
    }

    private func resumeGame() {
        pauseMenu?.removeFromParent()
        pauseMenu = nil
        setGameplayPaused(false)
        // Возвращаем экранные кнопки — если только их не скрывает геймпад.
        updateControlsVisibility()
    }

    /// Останавливает и возвращает к жизни всё, что идёт само: действия узлов
    /// (`isPaused`) и физику. Скорость физики выставляем отдельно, потому что
    /// `isPaused` сцены не наш — его сбрасывает SKView.
    private func setGameplayPaused(_ paused: Bool) {
        isPaused = paused
        physicsWorld.speed = paused ? 0 : 1
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
        // Набранные очки уходят в перенос — новая сцена стартует с ними, а не
        // с тем, что было на входе в уровень. Кроме очков за врагов, которые
        // сейчас вернутся на уровень: их модель снимет.
        let newProgress = GameProgressRules.playerDied(
            progress: progress,
            finalState: playerState,
            restoredEnemies: defeatedSinceCheckpoint,
            enemies: configuration.enemies
        )
        // Гибель уже свела очки с вернувшимися врагами — сохраняем результат,
        // иначе перезапуск игры вернул бы состояние до смерти.
        progressStore.save(newProgress)
        present(GameScene(configuration: configuration,
                          progress: newProgress,
                          store: progressStore))
    }

    private func completeLevel() {
        let newProgress = GameProgressRules.levelCompleted(
            progress: progress,
            finalState: playerState
        )

        if GameProgressRules.isGameCompleted(progress: newProgress, totalLevels: Levels.all.count) {
            // Игра пройдена — сохранение больше не нужно: следующий запуск
            // должен начать новую игру, а не воскрешать экран победы.
            progressStore.clear()
            presentVictory(progress: newProgress)
        } else {
            progressStore.save(newProgress)
            present(GameScene(configuration: Levels.all[newProgress.currentLevelIndex],
                              progress: newProgress,
                              store: progressStore))
        }
    }

    private func presentVictory(progress: GameProgress) {
        present(VictoryScene(size: size,
                             totalBonusPoints: progress.carriedBonusPoints,
                             store: progressStore))
    }

    /// Заменяет текущую сцену следующей. Единственное место, где это делается:
    /// смена сцены — не только `presentScene`, но и общий для всех переходов
    /// масштаб и снятие паузы.
    private func present(_ scene: SKScene) {
        scene.scaleMode = scaleMode
        // Уходящая сцена не должна остаться остановленной: на паузе не идёт и
        // анимация перехода.
        setGameplayPaused(false)
        view?.presentScene(scene, transition: .fade(withDuration: 0.5))
    }
}

// MARK: - Делегаты

extension GameScene: GameInputDelegate {

    func inputDidUpdateDirection(horizontal: CGFloat, vertical: CGFloat) {
        // На паузе ввод игнорируем. Экранные кнопки в это время скрыты, но
        // геймпад продолжает слать события, и они бы копились до снятия паузы.
        guard !isGamePaused else { return }
        // Горизонталь — аналоговая скорость персонажа; вертикаль — лазание по лестнице.
        player.setHorizontalInput(horizontal)
        ladderController.setVerticalInput(vertical)
    }

    func inputDidPressJump() {
        guard !isGamePaused else { return }

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
            // Запоминаем награду поднятой ДО применения события: смертельных
            // наград не бывает, но handle может перезапустить уровень, и запись
            // после него ушла бы уже в новую сцену.
            // Что переживает гибель, решает модель (PickupKind).
            if pickup.kind.staysCollectedAfterDeath {
                progress.collectedPickupIndices.insert(pickup.index)
            }
            // Сцена не разбирает виды наград: маппинг «вид → событие»
            // живёт в модели (PickupKind.event) и покрыт тестами.
            handle(pickup.kind.event)
            pickup.removeFromParent()
            return
        }

        // Контакт игрока с флагом — здесь он теперь и будет возрождаться.
        if let checkpointBody = bodyOfCategory(PhysicsCategory.checkpoint, in: bodies),
           let checkpoint = checkpointBody.node as? Checkpoint {
            activateCheckpoint(checkpoint)
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
