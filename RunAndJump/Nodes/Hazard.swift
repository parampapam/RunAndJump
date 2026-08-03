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
        addPit()
        addSurface(columns: columns, rows: rows, cell: cell)
    }

    /// Дно озера — заливка цветом неба во весь прямоугольник зоны.
    ///
    /// Жидкость полупрозрачна, и без дна сквозь неё просвечивал бы грунт с
    /// травой. Дно «вырезает» землю под озером, но рисуется **позади игрока**
    /// (`ZPosition.hazardPit`): у детей `zPosition` отсчитывается от родителя,
    /// поэтому здесь и вычитание — глобально дно ложится между травой и
    /// игровыми объектами, а плитки жидкости остаются поверх всех.
    private func addPit() {
        let pit = SKSpriteNode(color: ScenePalette.sky, size: size)
        pit.zPosition = ZPosition.hazardPit - ZPosition.hazard
        addChild(pit)
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
                // Прозрачность — на самих плитках, а не на узле: у детей альфа
                // перемножается с родительской, и дно перестало бы быть глухим.
                tile.alpha = kind.opacity
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

    /// Непрозрачность жидкости: сквозь неё просматривается всё, что под водой,
    /// в первую очередь утонувший по пояс игрок. Лава гуще воды.
    var opacity: CGFloat {
        switch self {
        case .water: return 0.7
        case .lava:  return 0.8
        }
    }
}
