//
//  Ladder.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.05.2026.
//

import SpriteKit

final class Ladder: SKNode {

    /// Габариты лестницы. Нужны сцене, чтобы вычислить нижний край
    /// (основание): по нему `LadderController` понимает, что игрок спустился
    /// до опоры — земли или платформы.
    let size: CGSize

    private static let ladderAtlas = SKTextureAtlas(named: "Ladder")

    /// - Parameter heightInTiles: запрошенная высота лестницы в тайлах.
    ///   Итоговый размер (`size`) может быть чуть больше — см. `LadderTiling`.
    init(heightInTiles: CGFloat) {
        let (tiles, totalHeightInTiles) = LadderTiling.layout(forRequestedHeightInTiles: heightInTiles)
        self.size = Grid.size(TileSize(width: ObjectSize.ladder.width, height: totalHeightInTiles))
        super.init()
        setupPhysics()
        setupVisual(tiles: tiles)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: size)
        // Лестница не двигается и не подвержена силам.
        body.isDynamic = false
        body.affectedByGravity = false

        body.categoryBitMask = PhysicsCategory.ladder
        // Ни с чем не сталкиваемся — игрок проходит сквозь.
        body.collisionBitMask = PhysicsCategory.none
        // Уведомление о пересечении с игроком получаем со стороны игрока;
        // здесь можно оставить 0 или продублировать — physics engine
        // зарегистрирует контакт, если хотя бы одна сторона его запросила.
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
    }

    private func setupVisual(tiles: [LadderTiling.Tile]) {
        var tileY = -size.height / 2
        for tile in tiles {
            let tileHeight = Grid.size(TileSize(width: ObjectSize.ladder.width, height: tile.heightInTiles)).height
            let texture = Ladder.ladderAtlas.textureNamed(tile.textureName)
            let node = SKSpriteNode(texture: texture, size: CGSize(width: size.width, height: tileHeight))
            tileY += tileHeight / 2
            node.position = CGPoint(x: 0, y: tileY)
            addChild(node)
            tileY += tileHeight / 2
        }
    }
}
