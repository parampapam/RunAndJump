//
//  GameScene.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

final class GameScene: SKScene {

    private var player: SKSpriteNode!
    private var ground: SKSpriteNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.5, green: 0.7, blue: 0.95, alpha: 1.0)

        setupGround()
        setupPlayer()
    }

    private func setupGround() {
        let groundSize = CGSize(width: size.width, height: 80)
        ground = SKSpriteNode(color: .brown, size: groundSize)
        // Позиционируем по центру нижнего края сцены.
        ground.position = CGPoint(x: size.width / 2, y: groundSize.height / 2)

        // Статическое физическое тело: не двигается само, но об него можно опереться.
        ground.physicsBody = SKPhysicsBody(rectangleOf: groundSize)
        ground.physicsBody?.isDynamic = false

        addChild(ground)
    }

    private func setupPlayer() {
        let playerSize = CGSize(width: 50, height: 50)
        player = SKSpriteNode(color: .red, size: playerSize)
        // Спавним игрока высоко над землёй, чтобы увидеть падение.
        player.position = CGPoint(x: size.width / 2, y: size.height - 100)

        // Динамическое тело: на него действует гравитация и столкновения.
        player.physicsBody = SKPhysicsBody(rectangleOf: playerSize)
        player.physicsBody?.isDynamic = true
        // Запрещаем вращение при столкновениях — иначе квадрат начнёт крутиться.
        player.physicsBody?.allowsRotation = false

        addChild(player)
    }
}
