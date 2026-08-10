//
//  GameHost.swift
//  RunAndJump
//

// Combine — явно: в проекте включён MEMBER_IMPORT_VISIBILITY, и реэкспорт из
// SwiftUI не делает ObservableObject видимым сам собой.
import Combine
import SpriteKit
import SwiftUI

/// Владелец игровой сцены — шов между SwiftUI и SpriteKit.
///
/// Существует ради времени жизни. `body` во SwiftUI пересчитывается когда
/// угодно и сколько угодно раз, а сцена создаётся ровно один раз за жизнь
/// экрана: собранная в `body` заново, она стёрла бы уровень, здоровье и очки
/// посреди игры. `@StateObject` — единственная обёртка, которая гарантирует
/// однократное создание, поэтому сцена лежит здесь, а не в `@State`.
///
/// Сцену дальше по игре пересоздаёт сама `GameScene` (гибель, следующий
/// уровень) — через `view.presentScene`, минуя SwiftUI. Здесь только самая
/// первая.
@MainActor
final class GameHost: ObservableObject {

    let scene: GameScene

    init(store: any GameProgressStore = UserDefaultsProgressStore()) {
        // Сохранение может быть от сборки с другим набором уровней — что из
        // него годится, решает чистое правило, а не хранилище.
        let saved = store.load()
        let levelCount = Levels.all.count
        let progress = GameProgressRules.resumable(saved, totalLevels: levelCount)
        // Продолженная партия открывается окном паузы: положение игрока внутри
        // уровня не сохраняется, и игрок должен увидеть, что продолжает с
        // последней точки восстановления, а не с того места, где закрыл игру.
        // Новая игра начинается сразу — предлагать в ней «продолжить» нечего.
        let pauseReason: PauseReason? =
            GameProgressRules.isResumable(saved, totalLevels: levelCount) ? .resumedSession : nil
        let scene = GameScene(
            configuration: Levels.all[progress.currentLevelIndex],
            progress: progress,
            store: store,
            pausedFor: pauseReason
        )
        scene.scaleMode = .resizeFill
        self.scene = scene
    }
}
