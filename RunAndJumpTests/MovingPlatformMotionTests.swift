//
//  MovingPlatformMotionTests.swift
//  RunAndJumpTests
//

import Testing
@testable import RunAndJump
import Foundation
import CoreGraphics

@Suite("MovingPlatformMotion")
struct MovingPlatformMotionTests {

    // Горизонтальная платформа: 0 → 100 по X, 50 pts/s, пауза 1 с. Путь = 100, полный ход = 2 с.
    private func horizontal(pause: TimeInterval = 1.0) -> MovingPlatformMotion {
        MovingPlatformMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 100, y: 0),
            speed: 50,
            pauseDuration: pause
        )
    }

    @Test("Старт — в начальной точке")
    func startsAtStartPosition() {
        let motion = horizontal()
        #expect(motion.position == .zero)
    }

    @Test("Едет к концу со скоростью speed")
    func movesTowardEnd() {
        var motion = horizontal()
        let p = motion.advance(by: 1.0)   // 50 pts за 1 с → половина пути
        #expect(p == CGPoint(x: 50, y: 0))
    }

    @Test("В конце — клампится, разворачивается и встаёт на паузу")
    func clampsAndReversesAtEnd() {
        var motion = horizontal()
        _ = motion.advance(by: 1.0)            // x = 50
        let atEnd = motion.advance(by: 1.0)    // дошёл бы до x = 100
        #expect(atEnd == CGPoint(x: 100, y: 0))

        // Сразу после разворота — пауза: позиция не меняется.
        let paused = motion.advance(by: 0.5)
        #expect(paused == CGPoint(x: 100, y: 0))
    }

    @Test("Во время паузы платформа стоит, после — едет обратно")
    func pausesThenMovesBack() {
        var motion = horizontal(pause: 1.0)
        _ = motion.advance(by: 1.0)   // x = 50
        _ = motion.advance(by: 1.0)   // x = 100, пауза 1.0

        // Выбираем паузу: 0.6 + 0.4 = 1.0, платформа всё ещё на месте.
        #expect(motion.advance(by: 0.6) == CGPoint(x: 100, y: 0))
        #expect(motion.advance(by: 0.4) == CGPoint(x: 100, y: 0))

        // Пауза истекла — едет обратно к старту.
        let back = motion.advance(by: 1.0)   // 50 pts назад
        #expect(back == CGPoint(x: 50, y: 0))
    }

    @Test("Диагональ интерполируется по обеим осям")
    func diagonalInterpolatesBothAxes() {
        // Путь 0→(60,80): длина = 100. За 1 с при speed 50 — прогресс 0.5.
        var motion = MovingPlatformMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 60, y: 80),
            speed: 50,
            pauseDuration: 0
        )
        #expect(motion.advance(by: 1.0) == CGPoint(x: 30, y: 40))
    }

    @Test("Нулевой путь (start == end) не двигает и не падает")
    func zeroDistanceStaysPut() {
        var motion = MovingPlatformMotion(
            startPosition: CGPoint(x: 10, y: 10),
            endPosition: CGPoint(x: 10, y: 10),
            speed: 50,
            pauseDuration: 0
        )
        #expect(motion.advance(by: 1.0) == CGPoint(x: 10, y: 10))
    }

    @Test("Нулевая пауза — разворот без простоя")
    func zeroPauseReversesImmediately() {
        var motion = horizontal(pause: 0)
        _ = motion.advance(by: 1.0)   // x = 50
        _ = motion.advance(by: 1.0)   // x = 100, разворот, пауза 0

        // Следующий же кадр едет обратно.
        #expect(motion.advance(by: 1.0) == CGPoint(x: 50, y: 0))
    }
}
