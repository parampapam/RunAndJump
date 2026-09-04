//
//  MovingPlatform.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 24.05.2026.
//

import SpriteKit

final class MovingPlatform: SKSpriteNode {

    private var motion: OscillatingMotion
    private var clock = FrameClock()

    /// Принимает уже переведённые в пункты центр и размер: преобразование из
    /// тайлов делает `LevelBuilder`.
    init(size: CGSize, textures: LevelTextures,
         startPosition: CGPoint, endPosition: CGPoint,
         speed: CGFloat, stops: [MotionStop]) {
        motion = OscillatingMotion(
            startPosition: startPosition,
            endPosition: endPosition,
            speed: speed,
            stops: stops
        )

        // Как и у неподвижной платформы, вид дают плитки-дети — узел невидим
        // и несёт только физику (см. `PlatformSkin`).
        super.init(texture: nil, color: .clear, size: size)

        PlatformSkin.tiles(forSize: size, textures: textures).forEach(addChild)

        position = motion.position   // = startPosition

        let body = SKPhysicsBody(
            edgeFrom: CGPoint(x: -size.width / 2, y: size.height / 2),
            to: CGPoint(x: size.width / 2, y: size.height / 2)
        )
        body.isDynamic = false
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.platform
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(at time: TimeInterval) {
        guard let dt = clock.tick(at: time) else { return }
        position = motion.advance(by: dt)
    }
}
