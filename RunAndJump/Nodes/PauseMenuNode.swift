//
//  PauseMenuNode.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 10.08.2026.
//

import SpriteKit

/// Окно паузы: затемнение на весь экран, заголовок и кнопки.
///
/// Узел ничего не решает: заголовок и набор кнопок приходят из чистой модели
/// `PauseMenu`, а выбор он отдаёт наружу через `onSelect`. Все
/// последствия (снять паузу, пересобрать уровень, начать игру заново) —
/// за сценой: сцена владеет прогрессом и иерархией.
///
/// Живёт ребёнком камеры — как HUD и экранное управление: там координаты
/// совпадают с экранными пунктами, и окно не уезжает вместе с миром.
final class PauseMenuNode: SKNode {

    private let onSelect: (PauseMenuAction) -> Void

    /// Кнопки в координатах узла — по ним разбирается касание. Держим отдельным
    /// списком, чтобы не искать узлы по имени и не хранить состояние в них.
    private var buttons: [(action: PauseMenuAction, frame: CGRect)] = []

    init(sceneSize: CGSize,
         onSelect: @escaping (PauseMenuAction) -> Void) {
        self.onSelect = onSelect
        super.init()

        // Поверх HUD и экранного управления (у обоих 1000): окно должно и
        // рисоваться сверху, и перехватывать касания раньше джойстика.
        zPosition = Layout.zPosition
        isUserInteractionEnabled = true

        addBackdrop(sceneSize: sceneSize)
        addPanel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Сборка

    /// Затемнение: и приглушает игру за окном, и глотает касания мимо кнопок.
    private func addBackdrop(sceneSize: CGSize) {
        // С запасом: экран мог стать больше после поворота, а окно собирается
        // один раз по размеру сцены на момент открытия.
        let size = CGSize(width: sceneSize.width * Layout.backdropOverscan,
                          height: sceneSize.height * Layout.backdropOverscan)
        addChild(SKSpriteNode(color: Palette.backdrop, size: size))
    }

    private func addPanel() {
        let items = PauseMenu.items

        let panelHeight = Layout.panelHeight(itemCount: items.count)
        let panelRect = CGRect(x: -Layout.panelWidth / 2, y: -panelHeight / 2,
                               width: Layout.panelWidth, height: panelHeight)

        let panel = SKShapeNode(rect: panelRect, cornerRadius: Layout.panelCornerRadius)
        panel.fillColor = Palette.panel
        panel.strokeColor = Palette.panelBorder
        panel.lineWidth = 1
        addChild(panel)

        // Раскладываем сверху вниз: курсор — центр очередной строки.
        var cursorY = panelRect.maxY - Layout.panelPadding - Layout.titleHeight / 2

        let title = label(PauseMenu.title,
                          fontNamed: "Helvetica-Bold",
                          size: Layout.titleFontSize,
                          color: Palette.title)
        title.position = CGPoint(x: 0, y: cursorY)
        addChild(title)
        cursorY -= Layout.titleHeight / 2

        for item in items {
            cursorY -= Layout.buttonSpacing + Layout.buttonSize.height / 2
            addButton(item, centerY: cursorY)
            cursorY -= Layout.buttonSize.height / 2
        }
    }

    private func addButton(_ item: PauseMenuItem, centerY: CGFloat) {
        let frame = CGRect(x: -Layout.buttonSize.width / 2,
                           y: centerY - Layout.buttonSize.height / 2,
                           width: Layout.buttonSize.width,
                           height: Layout.buttonSize.height)

        let shape = SKShapeNode(rect: frame, cornerRadius: Layout.buttonCornerRadius)
        shape.fillColor = Palette.buttonFill(for: item.action)
        shape.strokeColor = Palette.buttonBorder
        shape.lineWidth = 1
        addChild(shape)

        let caption = label(item.title,
                            fontNamed: "Helvetica-Bold",
                            size: Layout.buttonFontSize,
                            color: Palette.buttonText)
        caption.position = CGPoint(x: 0, y: centerY)
        addChild(caption)

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
        // Мимо кнопок — ничего не делаем: закрыть окно можно только «продолжить».
        guard let button = buttons.first(where: { $0.frame.contains(location) }) else { return }
        onSelect(button.action)
    }
}

// MARK: - Раскладка и цвета

private enum Layout {
    /// Выше HUD и экранного управления (1000).
    static let zPosition: CGFloat = 2000
    static let backdropOverscan: CGFloat = 1.5

    static let panelWidth: CGFloat = 300
    static let panelCornerRadius: CGFloat = 16
    static let panelPadding: CGFloat = 20

    static let titleHeight: CGFloat = 34
    static let titleFontSize: CGFloat = 28

    static let buttonSize = CGSize(width: 240, height: 44)
    static let buttonCornerRadius: CGFloat = 10
    static let buttonFontSize: CGFloat = 18
    static let buttonSpacing: CGFloat = 12

    static func panelHeight(itemCount: Int) -> CGFloat {
        panelPadding * 2
            + titleHeight
            + CGFloat(itemCount) * (buttonSize.height + buttonSpacing)
    }
}

private enum Palette {
    static let backdrop = SKColor(white: 0, alpha: 0.6)
    static let panel = SKColor(white: 0.12, alpha: 0.94)
    static let panelBorder = SKColor(white: 1, alpha: 0.25)

    static let title = SKColor.white
    static let buttonText = SKColor.white
    static let buttonBorder = SKColor(white: 1, alpha: 0.35)

    /// Продолжение — главное действие окна, поэтому выделено цветом; остальные
    /// одинаково нейтральные.
    static func buttonFill(for action: PauseMenuAction) -> SKColor {
        switch action {
        case .resume:
            return SKColor(red: 0.20, green: 0.55, blue: 0.30, alpha: 1)
        case .restartLevel, .mainMenu:
            return SKColor(white: 0.25, alpha: 1)
        }
    }
}
