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

    private static let atlas = SKTextureAtlas(named: "Hazards")


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
        let columns = max(1, Int((size.width / WorldMetrics.tileSize).rounded()))
        let rows = max(1, Int((size.height / WorldMetrics.tileSize).rounded()))
        let cell = CGSize(width: size.width / CGFloat(columns),
                          height: size.height / CGFloat(rows))
        alpha = kind.opacity
        addBacking(cell: cell)
        addSurface(columns: columns, rows: rows, cell: cell)
    }

    /// Подложка цветом жидкости под нижними рядами плиток: закрывает стыки
    /// рядов, чтобы сквозь них не просвечивала земля.
    ///
    /// Под верхним рядом подложки нет: там жидкость должна оставаться
    /// полупрозрачной (сквозь неё видно утонувшего игрока), а прозрачный
    /// гребень — рисовать силуэт волны на фоне неба. У озера в один ряд,
    /// как все нынешние, подложки не будет вовсе.
    private func addBacking(cell: CGSize) {
        let height = size.height - cell.height
        guard height > 0 else { return }

        let backing = SKSpriteNode(color: kind.deepColor,
                                   size: CGSize(width: size.width, height: height))
        backing.position = CGPoint(x: 0, y: -cell.height / 2)
        addChild(backing)
    }

    /// Плитки жидкости: два кадра со сдвинутыми волнами, поверхность
    /// перекатывается между ними. Все плитки идут в такт — на сдвиге фазы
    /// соседи показывали бы разные кадры, и волна ломалась бы на стыке.
    /// Чисто декоративно, зона урона от этого не меняется.
    private func addSurface(columns: Int, rows: Int, cell: CGSize) {
        let textures = AnimationFrames.Hazard.frames(for: kind).map(Self.atlas.textureNamed)
        // resize/restore = false: размер плитки задан сеткой, а не кадром.
        let animate = SKAction.animate(
            with: textures,
            timePerFrame: AnimationDuration.Hazard.timePerFrame(for: kind),
            resize: false,
            restore: false
        )

        for column in 0..<columns {
            for row in 0..<rows {
                let tile = SKSpriteNode(texture: textures.first, size: cell)
                tile.position = CGPoint(
                    x: -size.width / 2 + cell.width * (CGFloat(column) + 0.5),
                    y: size.height / 2 - cell.height * (CGFloat(row) + 0.5)
                )
                addChild(tile)

                guard textures.count > 1 else { continue }
                tile.run(.repeatForever(animate))
            }
        }
    }
}

/// Оформление озера. Живёт в слое узлов: модель (`HazardKind`) знает только про
/// механику и не имеет права видеть `SKColor`.
private extension HazardKind {

    /// Цвет подложки под плитками. Значения взяты из нижнего ряда пикселей
    /// самих плиток — так стык подложки и плитки не виден.
    var deepColor: SKColor {
        switch self {
        case .water: return SKColor(red: 97 / 255, green: 178 / 255, blue: 228 / 255, alpha: 1)
        case .lava:  return SKColor(red: 234 / 255, green: 146 / 255, blue: 31 / 255, alpha: 1)
        }
    }

    /// Непрозрачность жидкости: сквозь неё просматривается всё, что под водой,
    /// в первую очередь утонувший по пояс игрок. Лава гуще воды.
    var opacity: CGFloat {
        switch self {
        case .water: return 0.7
        case .lava:  return 0.8
        }
    }
}
