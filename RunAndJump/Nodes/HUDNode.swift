//
//  HUDNode.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 05.05.2026.
//

import SpriteKit

final class HUDNode: SKSpriteNode {

    /// Настройки шкалы: из них берётся потолок для «полного» бара
    /// и границы, на которых заливка меняет цвет.
    private let healthConfiguration: HealthConfiguration

    private let healthTrack: SKShapeNode
    private let healthFill: SKSpriteNode
    private let healthLabel: SKLabelNode
    private let bonusLabel: SKLabelNode
    private let pauseButton: PauseButton

    /// Нажатие кнопки паузы. Сцена подставляет сюда открытие окна паузы: HUD
    /// не знает ни про окно, ни про то, что значит «пауза».
    var onPauseTapped: (() -> Void)? {
        get { pauseButton.onTap }
        set { pauseButton.onTap = newValue }
    }

    init(sceneSize: CGSize, healthConfiguration: HealthConfiguration = .standard) {
        let barSize = CGSize(width: sceneSize.width * 0.85, height: 32)
        self.healthConfiguration = healthConfiguration

        let barX = Layout.leftInset
        let barY = -Layout.healthBarSize.height / 2
        let barRect = CGRect(origin: CGPoint(x: barX, y: barY), size: Layout.healthBarSize)

        healthTrack = SKShapeNode(rect: barRect, cornerRadius: Layout.healthBarCornerRadius)
        healthTrack.fillColor = HUDPalette.healthTrack
        healthTrack.strokeColor = HUDPalette.healthBorder
        healthTrack.lineWidth = 1
        healthTrack.zPosition = 1

        healthFill = SKSpriteNode(color: HUDPalette.healthy, size: Layout.healthBarSize)
        // Заливка поверх подложки — не полагаемся на порядок добавления детей.
        healthFill.zPosition = 2
        // Растим заливку от левого края: меняется только ширина, позиция — нет.
        healthFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthFill.position = CGPoint(x: barX, y: 0)

        healthLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        healthLabel.fontSize = barSize.height * 0.6
        healthLabel.fontColor = HUDPalette.text
        healthLabel.horizontalAlignmentMode = .left
        healthLabel.verticalAlignmentMode = .center
        healthLabel.position = CGPoint(x: barX + Layout.healthBarSize.width + Layout.gap, y: 0)

        bonusLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bonusLabel.fontSize = barSize.height * 0.6
        bonusLabel.fontColor = HUDPalette.text
        bonusLabel.horizontalAlignmentMode = .left
        bonusLabel.verticalAlignmentMode = .center
        bonusLabel.position = CGPoint(x: healthLabel.position.x + Layout.healthLabelWidth, y: 0)

        pauseButton = PauseButton()
        pauseButton.position = CGPoint(x: barSize.width - Layout.pauseButtonInset, y: 0)
        // Поверх подложки HUD: иначе касание достанется бару, а он не кнопка.
        pauseButton.zPosition = 3

        super.init(texture: nil, color: UIColor(red: 138, green: 138, blue: 138, alpha: 1), size: barSize)

        anchorPoint = .init(x: 0, y: 0.5)
        // Координаты относительно центра камеры: левый край бара, центр Y у верхней границы.
        position = CGPoint(x: -(barSize.width / 2), y: sceneSize.height / 2 - barSize.height)
        zPosition = 1000

        addChild(healthTrack)
        addChild(healthFill)
        addChild(healthLabel)
        addChild(bonusLabel)
        addChild(pauseButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with state: PlayerState) {
        let fraction = HealthRules.fillFraction(for: state.health, configuration: healthConfiguration)
        let level = HealthRules.level(for: state.health, configuration: healthConfiguration)

        // Ширина 0 у SKSpriteNode «схлопывает» узел, поэтому пустую шкалу прячем.
        let width = Layout.healthBarSize.width * CGFloat(fraction)
        healthFill.isHidden = width <= 0
        healthFill.color = HUDPalette.fill(for: level)
        healthFill.run(.resize(toWidth: max(width, 0.01), duration: Layout.fillDuration))

        healthLabel.text = "\(state.health)/\(healthConfiguration.maximum)"
        bonusLabel.text = "Bonus: \(state.bonusPoints)"
    }
}

// MARK: - Раскладка и цвета HUD

/// Размеры полосы здоровья и отступы. Держим их здесь, а не в теле узла:
/// подправить вид HUD — это правка одного места.
private enum Layout {
    static let leftInset: CGFloat = 12
    static let gap: CGFloat = 8
    static let healthBarSize = CGSize(width: 140, height: 14)
    static let healthBarCornerRadius: CGFloat = 3
    /// Место под надпись «200/200» — от неё считается позиция бонуса.
    static let healthLabelWidth: CGFloat = 92
    /// Короткая анимация: заметно, что здоровье убыло, но HUD не «плывёт».
    static let fillDuration: TimeInterval = 0.15
    /// Отступ кнопки паузы от правого края бара.
    static let pauseButtonInset: CGFloat = 18
}

/// Цвета HUD. Заливка шкалы зависит от `HealthLevel` — границы уровней
/// считает модель (`HealthRules`), здесь только сопоставление цвета.
private enum HUDPalette {
    static let text = SKColor.darkGray
    static let healthTrack = SKColor(white: 0.25, alpha: 0.35)
    static let healthBorder = SKColor(white: 0.15, alpha: 0.6)

    static let healthy = SKColor(red: 0.30, green: 0.78, blue: 0.35, alpha: 1)
    static let warning = SKColor(red: 0.95, green: 0.75, blue: 0.20, alpha: 1)
    static let critical = SKColor(red: 0.90, green: 0.25, blue: 0.20, alpha: 1)

    static func fill(for level: HealthLevel) -> SKColor {
        switch level {
        case .healthy:  return healthy
        case .warning:  return warning
        case .critical: return critical
        }
    }
}
