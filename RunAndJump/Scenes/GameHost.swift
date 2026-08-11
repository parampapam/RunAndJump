//
//  GameHost.swift
//  RunAndJump
//

// Combine — явно: в проекте включён MEMBER_IMPORT_VISIBILITY, и реэкспорт из
// SwiftUI не делает ObservableObject видимым сам собой.
import Combine
import SpriteKit
import SwiftUI

/// Владелец первой сцены — шов между SwiftUI и SpriteKit.
///
/// Существует ради времени жизни. `body` во SwiftUI пересчитывается когда
/// угодно и сколько угодно раз, а сцена создаётся ровно один раз за жизнь
/// экрана: собранная в `body` заново, она стёрла бы уровень, здоровье и очки
/// посреди игры. `@StateObject` — единственная обёртка, которая гарантирует
/// однократное создание, поэтому сцена лежит здесь, а не в `@State`.
///
/// Дальше сцены сменяют друг друга сами — через `view.presentScene`, минуя
/// SwiftUI: меню открывает уровень, уровень пересоздаёт себя при гибели и на
/// следующем уровне. Здесь только самая первая.
///
/// Тип свойства — `SKScene`, а не `GameScene`: с точки зрения SwiftUI это
/// просто «то, что показывает `SpriteView`», и знать, какой именно экран сейчас
/// открыт, ему незачем.
@MainActor
final class GameHost: ObservableObject {

    let scene: SKScene

    init(store: any GameProgressStore = UserDefaultsProgressStore()) {
        // Запуск всегда открывает главное меню — и после первой установки, и с
        // сохранённой партией. Решение «начать заново или продолжить» принимает
        // игрок, а не код на старте; сохранение меню читает само, чтобы понять,
        // предлагать ли «продолжить».
        let scene = MainMenuScene(store: store)
        scene.scaleMode = .resizeFill
        self.scene = scene
    }
}
