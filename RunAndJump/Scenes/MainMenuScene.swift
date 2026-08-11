//
//  MainMenuScene.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 11.08.2026.
//

import SpriteKit

/// Главное меню — первое, что видит игрок при запуске.
///
/// Отдельная **сцена**, а не окно поверх игры: пока меню открыто, игрового
/// уровня не существует вовсе — ни узлов, ни физики, ни кадров, — поэтому и
/// показать сквозь меню нечего. Окно паузы (`PauseMenuNode`) устроено иначе
/// именно потому, что там за ним обязан быть виден живой уровень.
///
/// Живёт в SpriteKit и уходит через `presentScene`, как `VictoryScene`: смена
/// сцен в этом проекте не поднимается до SwiftUI (см. `GameHost`).
///
/// Узел ничего не решает: заголовок, набор пунктов и их доступность приходят из
/// чистой модели `MainMenu`; сцена лишь спрашивает хранилище, есть ли что
/// продолжать, и собирает игровую сцену по выбору игрока.
@MainActor
final class MainMenuScene: SKScene {

    /// Хранилище прогресса: у него меню спрашивает, есть ли сохранённая партия,
    /// и его же передаёт дальше игровой сцене — та должна сохраняться.
    private let progressStore: any GameProgressStore

    /// Кнопки в координатах сцены — по ним разбирается касание. Держим отдельным
    /// списком, чтобы не искать узлы по имени и не хранить состояние в них.
    /// Выключенные пункты сюда не попадают и потому не нажимаются.
    private var buttons: [(action: MainMenuAction, frame: CGRect)] = []

    init(store: any GameProgressStore) {
        self.progressStore = store
        // Размер поставит SKView — сцена показывается с `scaleMode = .resizeFill`.
        // До этого момента раскладка уже верна: якорь в центре, и всё меню
        // строится относительно него, а не от углов.
        super.init(size: CGSize(width: 1024, height: 768))
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Жизненный цикл

    override func didMove(to view: SKView) {
        backgroundColor = Palette.background

        // Спрашиваем хранилище здесь, а не в `init`: меню переживает возврат из
        // игры, и к этому моменту сохранение может быть уже другим.
        let hasSavedGame = GameProgressRules.isResumable(progressStore.load(),
                                                         totalLevels: Levels.all.count)
        removeAllChildren()
        buttons.removeAll()
        build(hasSavedGame: hasSavedGame)
    }

    // MARK: - Сборка

    private func build(hasSavedGame: Bool) {
        let items = MainMenu.items(hasSavedGame: hasSavedGame)

        // Раскладываем сверху вниз от середины экрана: курсор — центр очередной
        // строки. Высоту считаем заранее, чтобы меню стояло по центру целиком, а
        // не свисало вниз от заголовка.
        var cursorY = Layout.contentHeight(itemCount: items.count) / 2 - Layout.titleHeight / 2

        let title = label(MainMenu.title,
                          fontNamed: "Helvetica-Bold",
                          size: Layout.titleFontSize,
                          color: Palette.title)
        title.position = CGPoint(x: 0, y: cursorY)
        addChild(title)
        cursorY -= Layout.titleHeight / 2 + Layout.titleGap

        for item in items {
            cursorY -= Layout.buttonSize.height / 2
            addButton(item, centerY: cursorY)
            cursorY -= Layout.buttonSize.height / 2 + Layout.buttonSpacing
        }
    }

    private func addButton(_ item: MainMenuItem, centerY: CGFloat) {
        let frame = CGRect(x: -Layout.buttonSize.width / 2,
                           y: centerY - Layout.buttonSize.height / 2,
                           width: Layout.buttonSize.width,
                           height: Layout.buttonSize.height)

        let shape = SKShapeNode(rect: frame, cornerRadius: Layout.buttonCornerRadius)
        shape.fillColor = Palette.buttonFill(for: item)
        shape.strokeColor = Palette.buttonBorder(for: item)
        shape.lineWidth = 1
        addChild(shape)

        let caption = label(item.title,
                            fontNamed: "Helvetica-Bold",
                            size: Layout.buttonFontSize,
                            color: Palette.buttonText(for: item))
        caption.position = CGPoint(x: 0, y: centerY)
        addChild(caption)

        // Выключенный пункт остаётся на экране, но касание по нему — не событие.
        guard item.isEnabled else { return }
        buttons.append((item.action, frame))
    }

    private func label(_ text: String, fontNamed: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: fontNamed)
        node.text = text
        node.fontSize = size
        node.fontColor = color
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
        return node
    }

    // MARK: - Касания

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard let button = buttons.first(where: { $0.frame.contains(location) }) else { return }
        handle(button.action)
    }

    // MARK: - Выбор игрока

    private func handle(_ action: MainMenuAction) {
        switch action {
        case .newGame:
            // Новая партия начинается с чистого листа: сохранение стираем, чтобы
            // следующий запуск не предложил продолжить брошенную игру. То же
            // правило, что и у одноимённого пункта окна паузы.
            progressStore.clear()
            present(GameScene(configuration: Levels.all[0],
                              progress: .initial,
                              store: progressStore))

        case .continueGame:
            // Годность сохранения решает то же чистое правило, что и на запуске:
            // за время показа меню оно не изменится, но второй копии условий
            // здесь быть не должно. Если сохранение вдруг непригодно, `resumable`
            // вернёт начальный прогресс — игра начнётся сначала, но не упадёт.
            let progress = GameProgressRules.resumable(progressStore.load(),
                                                       totalLevels: Levels.all.count)
            present(GameScene(configuration: Levels.all[progress.currentLevelIndex],
                              progress: progress,
                              store: progressStore))

        case .settings, .about:
            // Экранов ещё нет, и пункты выключены — сюда мы не попадаем.
            // Случаи оставлены явными: новый раздел должен «сломать» switch,
            // а не тихо провалиться в `default`.
            break
        }
    }

    private func present(_ scene: SKScene) {
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .fade(withDuration: 0.5))
    }
}

// MARK: - Раскладка и цвета

private enum Layout {
    static let titleHeight: CGFloat = 52
    static let titleFontSize: CGFloat = 44
    /// Отступ от заголовка до первой кнопки.
    static let titleGap: CGFloat = 24

    static let buttonSize = CGSize(width: 260, height: 46)
    static let buttonCornerRadius: CGFloat = 10
    static let buttonFontSize: CGFloat = 18
    static let buttonSpacing: CGFloat = 12

    /// Полная высота меню — нужна, чтобы центрировать его целиком.
    static func contentHeight(itemCount: Int) -> CGFloat {
        titleHeight
            + titleGap
            + CGFloat(itemCount) * buttonSize.height
            + CGFloat(max(0, itemCount - 1)) * buttonSpacing
    }
}

private enum Palette {
    /// Собственный фон, а не небо уровня: за меню игры нет, и притворяться, что
    /// она там есть, незачем.
    static let background = SKColor(red: 0.07, green: 0.09, blue: 0.14, alpha: 1)

    static let title = SKColor.white
    static let buttonBorderColor = SKColor(white: 1, alpha: 0.35)

    /// Главное действие экрана выделено цветом; остальные доступные пункты
    /// одинаково нейтральные. Выключенные гаснут целиком — и заливкой, и рамкой,
    /// и подписью, — чтобы недоступность читалась сразу.
    ///
    /// Какой пункт главный, решает модель (`MainMenuItem.isPrimary`), а не этот
    /// `switch` по действию: правило зависит от сохранения, и держать его здесь
    /// значило бы держать логику в узле.
    static func buttonFill(for item: MainMenuItem) -> SKColor {
        guard item.isEnabled else { return SKColor(white: 0.18, alpha: 1) }
        return item.isPrimary
            ? SKColor(red: 0.20, green: 0.55, blue: 0.30, alpha: 1)
            : SKColor(white: 0.25, alpha: 1)
    }

    static func buttonBorder(for item: MainMenuItem) -> SKColor {
        item.isEnabled ? buttonBorderColor : SKColor(white: 1, alpha: 0.12)
    }

    static func buttonText(for item: MainMenuItem) -> SKColor {
        item.isEnabled ? .white : SKColor(white: 0.45, alpha: 1)
    }
}
