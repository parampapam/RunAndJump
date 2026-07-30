//
//  Hazard.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 30.07.2026.
//

import SpriteKit

/// Опасная зона на земле — озеро воды или лавы.
///
/// Узел ничего не решает: он рисует поверхность и несёт физическое тело-триггер
/// (сквозь озеро можно пройти, но контакт с игроком регистрируется). Сколько
/// здоровья снимает попадание и как часто озеро может ударить снова — знает
/// чистая модель `HazardKind`, применяет её сцена.
final class Hazard: SKNode {

    let kind: HazardKind

    /// Габариты озера в пунктах. Это же — прямоугольник зоны урона.
    let size: CGSize

    // MARK: - Оформление поверхности

    /// Высота полосы «ряби» на поверхности.
    private static let surfaceHeight: CGFloat = WorldMetrics.tileSize * 0.16
    /// Ширина одного сегмента ряби — по нему считается их количество.
    private static let segmentWidth: CGFloat = WorldMetrics.tileSize / 2
    /// Размах колебания сегмента вверх-вниз.
    private static let waveAmplitude: CGFloat = WorldMetrics.tileSize * 0.05
    /// Полный цикл волны, секунды.
    private static let waveDuration: TimeInterval = 1.2

    init(kind: HazardKind, size: CGSize) {
        self.kind = kind
        self.size = size
        super.init()
        zPosition = ZPosition.hazard
        setupPhysics()
        setupVisual()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: size)
        // Озеро неподвижно и не подвержено силам.
        body.isDynamic = false
        body.affectedByGravity = false

        body.categoryBitMask = PhysicsCategory.hazard
        // Ни с чем не сталкиваемся — в озеро можно войти, оно не преграда.
        body.collisionBitMask = PhysicsCategory.none
        // Контакт запрашивает игрок (как с лестницей и наградами).
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
    }

    private func setupVisual() {
        let basin = SKSpriteNode(color: kind.deepColor, size: size)
        addChild(basin)

        if kind.glows {
            // Лава «дышит»: жар то ярче, то тусклее.
            basin.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.75, duration: Self.waveDuration / 2),
                .fadeAlpha(to: 1.0, duration: Self.waveDuration / 2)
            ])))
        }

        addSurfaceRipple()
    }

    /// Поверхность — ряд сегментов, качающихся вверх-вниз со сдвигом фазы:
    /// по озеру бежит волна. Чисто декоративно, зона урона от этого не меняется.
    private func addSurfaceRipple() {
        let count = max(1, Int((size.width / Self.segmentWidth).rounded()))
        let segmentWidth = size.width / CGFloat(count)
        let surfaceY = size.height / 2 - Self.surfaceHeight / 2

        for index in 0..<count {
            let segment = SKSpriteNode(
                color: kind.surfaceColor,
                size: CGSize(width: segmentWidth, height: Self.surfaceHeight)
            )
            segment.position = CGPoint(
                x: -size.width / 2 + segmentWidth * (CGFloat(index) + 0.5),
                y: surfaceY
            )
            addChild(segment)

            let up = SKAction.moveBy(x: 0, y: Self.waveAmplitude, duration: Self.waveDuration / 2)
            up.timingMode = .easeInEaseOut
            let down = up.reversed()
            let phase = Self.waveDuration * Double(index) / Double(count)
            segment.run(.sequence([
                .wait(forDuration: phase),
                .repeatForever(.sequence([up, down]))
            ]))
        }
    }
}

/// Палитра озёр. Живёт в слое узлов: модель (`HazardKind`) знает только про
/// механику и не имеет права видеть `SKColor`.
private extension HazardKind {

    /// Цвет толщи — основная заливка озера.
    var deepColor: SKColor {
        switch self {
        case .water: return SKColor(red: 0.13, green: 0.42, blue: 0.78, alpha: 0.85)
        case .lava:  return SKColor(red: 0.72, green: 0.16, blue: 0.05, alpha: 0.95)
        }
    }

    /// Цвет поверхности — светлее толщи, им нарисована рябь.
    var surfaceColor: SKColor {
        switch self {
        case .water: return SKColor(red: 0.45, green: 0.75, blue: 0.95, alpha: 0.9)
        case .lava:  return SKColor(red: 0.98, green: 0.65, blue: 0.15, alpha: 1.0)
        }
    }

    /// Пульсирует ли заливка (жар лавы).
    var glows: Bool {
        switch self {
        case .water: return false
        case .lava:  return true
        }
    }
}
