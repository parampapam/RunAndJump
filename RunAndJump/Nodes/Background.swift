//
//  Background.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 15.08.2026.
//

import SpriteKit

/// Фон уровня: сплошная заливка и две полосы поверх неё, едущие с параллаксом.
/// Узел ничего не решает — что из чего собрано, говорит `BackgroundDescriptor`,
/// где что лежит, считает `BackgroundLayout`, а чем нарисован сегмент, знает
/// `BackgroundTextures`.
///
/// Перевод тайлов в пункты здесь идёт через `Grid` — как и в `LevelBuilder`.
/// Вынести его целиком в билдер нельзя: положение полос меняется каждый кадр
/// вслед за камерой, а не один раз при сборке уровня.
final class Background: SKNode {

    private let descriptor: BackgroundDescriptor
    private let levelSizeInTiles: TileSize

    private let horizonStrip = SKNode()
    private let skyStrip = SKNode()
    /// Размер видимой области, под который собраны спрайты полос. Меняется на
    /// повороте экрана — тогда количество сегментов пересчитывается заново.
    private var builtViewport: TileSize?

    init(descriptor: BackgroundDescriptor, levelSizeInTiles: TileSize) {
        self.descriptor = descriptor
        self.levelSizeInTiles = levelSizeInTiles
        super.init()

        addChild(makeFill())

        horizonStrip.zPosition = ZPosition.backgroundHorizon
        skyStrip.zPosition = ZPosition.backgroundSky
        addChild(horizonStrip)
        addChild(skyStrip)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Ставит полосы под текущую камеру. Зовётся каждый кадр после `updateCamera`.
    func update(viewportSizeInTiles viewport: TileSize, cameraCenterInTiles camera: CGPoint) {
        if builtViewport != viewport {
            rebuild(viewport: viewport)
            builtViewport = viewport
        }

        let horizon = BackgroundLayout.horizon(descriptor,
                                               levelSizeInTiles: levelSizeInTiles,
                                               viewportSizeInTiles: viewport,
                                               cameraCenterInTiles: camera)
        let sky = BackgroundLayout.sky(descriptor,
                                       levelSizeInTiles: levelSizeInTiles,
                                       viewportSizeInTiles: viewport,
                                       cameraCenterInTiles: camera)

        horizonStrip.position = Grid.point(TileCoordinate(x: horizon.origin.x, y: horizon.origin.y))
        skyStrip.position = Grid.point(TileCoordinate(x: sky.origin.x, y: sky.origin.y))
    }

    // MARK: - Сборка

    /// Заливка кладётся на весь уровень целиком, а не привязывается к камере:
    /// это один спрайт с одноцветной текстурой, зато его не нужно двигать
    /// каждый кадр и негде промахнуться.
    private func makeFill() -> SKSpriteNode {
        let texture = SKTexture(imageNamed: BackgroundTextures.name(for: descriptor.fill))
        let fill = SKSpriteNode(texture: texture)
        fill.size = Grid.size(levelSizeInTiles)
        fill.position = Grid.center(origin: TileCoordinate(x: 0, y: 0), size: levelSizeInTiles)
        fill.zPosition = ZPosition.background
        return fill
    }

    private func rebuild(viewport: TileSize) {
        // Камера в начале уровня: раскладка сегментов внутри полосы от
        // положения камеры не зависит, меняется только положение самой полосы.
        let camera = CGPoint(x: viewport.width / 2, y: viewport.height / 2)

        let horizon = BackgroundLayout.horizon(descriptor,
                                               levelSizeInTiles: levelSizeInTiles,
                                               viewportSizeInTiles: viewport,
                                               cameraCenterInTiles: camera)
        let sky = BackgroundLayout.sky(descriptor,
                                       levelSizeInTiles: levelSizeInTiles,
                                       viewportSizeInTiles: viewport,
                                       cameraCenterInTiles: camera)

        fill(strip: horizonStrip, with: horizon.placements) { index in
            BackgroundTextures.name(for: descriptor.horizon.segments[index])
        }
        fill(strip: skyStrip, with: sky.placements) { index in
            BackgroundTextures.name(for: descriptor.sky.segments[index])
        }
    }

    private func fill(strip: SKNode,
                      with placements: [BackgroundLayout.Placement],
                      textureName: (Int) -> String?) {
        strip.removeAllChildren()
        for placement in placements {
            // nil — сегмент ничего не рисует, и на его месте видна заливка.
            guard let name = textureName(placement.segmentIndex) else { continue }
            let sprite = SKSpriteNode(texture: SKTexture(imageNamed: name))
            sprite.size = Grid.size(placement.rect.size)
            sprite.position = Grid.center(of: placement.rect)
            strip.addChild(sprite)
        }
    }
}
