//
//  OscillatingMotionTests.swift
//  RunAndJumpTests
//

import Testing
@testable import RunAndJump
import Foundation
import CoreGraphics

@Suite("OscillatingMotion")
struct OscillatingMotionTests {

    // Горизонтальная платформа: 0 → 100 по X, 50 pts/s, паузы в концах.
    // Путь = 100, полный ход = 2 с.
    private func horizontal(pause: TimeInterval = 1.0) -> OscillatingMotion {
        OscillatingMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 100, y: 0),
            speed: 50,
            stops: MotionStop.atEnds(pause)
        )
    }

    // Тот же отрезок, но остановки задаются вызывающим.
    private func horizontal(stops: [MotionStop]) -> OscillatingMotion {
        OscillatingMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 100, y: 0),
            speed: 50,
            stops: stops
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
        var motion = OscillatingMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 60, y: 80),
            speed: 50
        )
        #expect(motion.advance(by: 1.0) == CGPoint(x: 30, y: 40))
    }

    @Test("Нулевой путь (start == end) не двигает и не падает")
    func zeroDistanceStaysPut() {
        var motion = OscillatingMotion(
            startPosition: CGPoint(x: 10, y: 10),
            endPosition: CGPoint(x: 10, y: 10),
            speed: 50
        )
        #expect(motion.advance(by: 1.0) == CGPoint(x: 10, y: 10))
    }

    @Test("Старт с заданного прогресса — для врага из середины отрезка")
    func startsAtInitialProgress() {
        var motion = OscillatingMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 100, y: 0),
            speed: 50,
            initialProgress: 0.5
        )
        // Начинает с середины…
        #expect(motion.position == CGPoint(x: 50, y: 0))
        // …и едет к концу (направление по умолчанию — к endPosition).
        #expect(motion.advance(by: 1.0) == CGPoint(x: 100, y: 0))
    }

    @Test("initialProgress клампится в [0, 1]")
    func initialProgressIsClamped() {
        let below = OscillatingMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 100, y: 0),
            speed: 50,
            initialProgress: -3
        )
        #expect(below.position == .zero)

        let above = OscillatingMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 100, y: 0),
            speed: 50,
            initialProgress: 5
        )
        #expect(above.position == CGPoint(x: 100, y: 0))
    }

    @Test("Без остановок — разворот в конце без простоя")
    func noStopsReverseImmediately() {
        var motion = horizontal(stops: [])
        _ = motion.advance(by: 1.0)   // x = 50
        _ = motion.advance(by: 1.0)   // x = 100, разворот

        // Следующий же кадр едет обратно.
        #expect(motion.advance(by: 1.0) == CGPoint(x: 50, y: 0))
    }

    // MARK: Остановки на маршруте

    @Test("Остановка в середине: платформа встаёт ровно на ней")
    func stopsAtMidpoint() {
        var motion = horizontal(stops: [.at(0.5, 1.0)])

        // Кадр в 0.8 с довёз бы до x = 40 — остановки ещё нет.
        #expect(motion.advance(by: 0.8) == CGPoint(x: 40, y: 0))

        // Следующий кадр перескочил бы середину (x = 65), но платформа встаёт
        // ровно на 50 — точка замирания не зависит от частоты кадров.
        // Доезд занял 0.2 с из 0.5, остальные 0.3 с уже пошли в паузу.
        #expect(motion.advance(by: 0.5) == CGPoint(x: 50, y: 0))
        #expect(motion.advance(by: 0.7) == CGPoint(x: 50, y: 0))

        // Пауза истекла — едет дальше в ту же сторону, а не назад.
        #expect(motion.advance(by: 1.0) == CGPoint(x: 100, y: 0))
    }

    @Test("Отстояв паузу, платформа трогается, а не залипает на остановке")
    func doesNotRetriggerStopItStandsOn() {
        var motion = horizontal(stops: [.at(0.5, 0.5)])
        _ = motion.advance(by: 1.0)                        // встала на x = 50
        _ = motion.advance(by: 0.5)                        // выстояла паузу

        // Три кадра подряд — платформа уезжает, а не встаёт снова.
        #expect(motion.advance(by: 0.2) == CGPoint(x: 60, y: 0))
        #expect(motion.advance(by: 0.2) == CGPoint(x: 70, y: 0))
        #expect(motion.advance(by: 0.2) == CGPoint(x: 80, y: 0))
    }

    @Test("Остановка срабатывает и на обратном ходу")
    func stopWorksInBothDirections() {
        var motion = horizontal(stops: [.at(0.5, 1.0)])
        _ = motion.advance(by: 1.0)    // встала на x = 50
        _ = motion.advance(by: 1.0)    // выстояла
        _ = motion.advance(by: 1.0)    // x = 100, разворот без паузы (её нет в конце)

        // Обратно: снова встаёт на середине.
        #expect(motion.advance(by: 1.0) == CGPoint(x: 50, y: 0))
        #expect(motion.advance(by: 0.9) == CGPoint(x: 50, y: 0))
        #expect(motion.advance(by: 0.1) == CGPoint(x: 50, y: 0))
        #expect(motion.advance(by: 1.0) == CGPoint(x: 0, y: 0))
    }

    @Test("Пауза в начале, в середине, без паузы в конце")
    func differentPausesAlongRoute() {
        var motion = horizontal(stops: [.start(0.5), .at(0.5, 1.0)])

        // Едем от старта: встаём на середине на 1 с.
        _ = motion.advance(by: 1.0)                            // x = 50
        #expect(motion.advance(by: 1.0) == CGPoint(x: 50, y: 0))

        // Доезжаем до конца — паузы там нет, следующий кадр уже едет назад.
        #expect(motion.advance(by: 1.0) == CGPoint(x: 100, y: 0))
        #expect(motion.advance(by: 0.5) == CGPoint(x: 75, y: 0))

        // Назад через середину — снова пауза 1 с.
        #expect(motion.advance(by: 0.5) == CGPoint(x: 50, y: 0))
        #expect(motion.advance(by: 1.0) == CGPoint(x: 50, y: 0))

        // Возвращаемся к старту — там пауза 0.5 с.
        #expect(motion.advance(by: 1.0) == CGPoint(x: 0, y: 0))
        #expect(motion.advance(by: 0.25) == CGPoint(x: 0, y: 0))
        #expect(motion.advance(by: 0.25) == CGPoint(x: 0, y: 0))
        // Пауза истекла — снова к концу.
        #expect(motion.advance(by: 0.25) == CGPoint(x: 12.5, y: 0))
    }

    @Test("Несколько остановок за кадр — встаём на первой по ходу")
    func picksNearestStopWhenFrameSkipsSeveral() {
        var motion = horizontal(stops: [.at(0.3, 1.0), .at(0.6, 1.0)])

        // Кадр в 1 с перекрыл бы обе остановки — встаём на ближайшей, x = 30
        // (доезд 0.6 с, оставшиеся 0.4 с ушли в паузу).
        #expect(motion.advance(by: 1.0) == CGPoint(x: 30, y: 0))
        #expect(motion.advance(by: 0.6) == CGPoint(x: 30, y: 0))   // достояли

        // Дальше — на следующей, x = 60.
        #expect(motion.advance(by: 1.0) == CGPoint(x: 60, y: 0))
    }

    @Test("Остановка на конце важнее клампа: пауза, потом разворот")
    func stopAtEndPausesThenReverses() {
        var motion = horizontal(stops: [.end(1.0)])

        // Кадр перелетел бы конец — клампимся и встаём. Доезд занял 2 с,
        // оставшиеся 0.5 с кадра уже пошли в паузу.
        #expect(motion.advance(by: 2.5) == CGPoint(x: 100, y: 0))
        #expect(motion.advance(by: 0.5) == CGPoint(x: 100, y: 0))
        // Пауза вышла — едем назад.
        #expect(motion.advance(by: 1.0) == CGPoint(x: 50, y: 0))
    }

    @Test("Неположительная остановка игнорируется")
    func nonPositiveStopsAreDropped() {
        var motion = horizontal(stops: [.at(0.5, 0), .at(0.75, -1)])

        // Ни на 50, ни на 75 не тормозим: кадр в 2 с проходит весь отрезок.
        #expect(motion.advance(by: 2.0) == CGPoint(x: 100, y: 0))
    }

    @Test("Прогресс остановки клампится в [0, 1]")
    func stopProgressIsClamped() {
        #expect(MotionStop.at(-2, 1).progress == 0)
        #expect(MotionStop.at(7, 1).progress == 1)
    }

    // MARK: Остаток кадра

    @Test("Досидев паузу, платформа едет остатком того же кадра")
    func leftoverTimeAfterPauseIsSpentMoving() {
        var motion = horizontal(stops: [.at(0.5, 1.0)])
        _ = motion.advance(by: 1.0)   // встала на x = 50, пауза 1 с

        // Кадр в 1.5 с: 1 с на паузу, 0.5 с на дорогу — это 25 pts.
        #expect(motion.advance(by: 1.5) == CGPoint(x: 75, y: 0))
    }

    @Test("Доезд до остановки не съедает кадр: пауза начинается сразу")
    func arrivalAtStopStartsPauseWithinTheSameFrame() {
        var motion = horizontal(stops: [.at(0.5, 1.0)])

        // 1 с на дорогу до середины + 0.4 с паузы = от паузы осталось 0.6 с.
        #expect(motion.advance(by: 1.4) == CGPoint(x: 50, y: 0))
        #expect(motion.advance(by: 0.6) == CGPoint(x: 50, y: 0))
        #expect(motion.advance(by: 0.2) == CGPoint(x: 60, y: 0))
    }

    @Test("Длинный кадр проходит короткую остановку насквозь")
    func longFrameCrossesShortStop() {
        var motion = horizontal(stops: [.at(0.5, 0.2)])

        // 1 с до середины + 0.2 с стоим + 0.8 с едем (40 pts) = x = 90.
        #expect(motion.advance(by: 2.0) == CGPoint(x: 90, y: 0))
    }

    @Test("Разворот на конце тоже не съедает остаток кадра")
    func reversalAtEndKeepsLeftoverTime() {
        var motion = horizontal(stops: [])

        // 2 с до конца + 1 с назад: разворот происходит внутри кадра и времени
        // не стоит.
        #expect(motion.advance(by: 3.0) == CGPoint(x: 50, y: 0))
    }

    @Test("Старт ровно на остановке начинается с движения")
    func initialProgressOnStopDoesNotPause() {
        var motion = OscillatingMotion(
            startPosition: .zero,
            endPosition: CGPoint(x: 100, y: 0),
            speed: 50,
            stops: [.at(0.5, 1.0)],
            initialProgress: 0.5
        )
        #expect(motion.advance(by: 0.2) == CGPoint(x: 60, y: 0))
    }
}
