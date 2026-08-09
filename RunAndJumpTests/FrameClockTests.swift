//
//  FrameClockTests.swift
//  RunAndJumpTests
//

import Testing
@testable import RunAndJump
import Foundation

@Suite("FrameClock")
struct FrameClockTests {

    // Метки времени в тестах — двоичные дроби (0.25, 0.125): их разность
    // считается точно, и сравнение через == не зависит от погрешности double.

    @Test("Первый кадр только фиксирует время и возвращает nil")
    func firstTickReturnsNil() {
        var clock = FrameClock()
        #expect(clock.tick(at: 10) == nil)
    }

    @Test("Со второго кадра возвращает дельту с прошлого")
    func returnsDeltaAfterFirst() {
        var clock = FrameClock(maximumDelta: 1)
        _ = clock.tick(at: 10)
        #expect(clock.tick(at: 10.25) == 0.25)
        #expect(clock.tick(at: 10.75) == 0.5)
    }

    @Test("Одинаковая метка времени даёт нулевую дельту")
    func sameTimeYieldsZero() {
        var clock = FrameClock()
        _ = clock.tick(at: 10)
        #expect(clock.tick(at: 10) == 0)
    }

    // MARK: - Потолок дельты

    /// Приложение свернули на минуту: часы кадров шли, рендер стоял. Без
    /// потолка враги и платформы сделали бы один шаг на 60 секунд.
    @Test("Долгий перерыв обрезается до потолка")
    func longPauseIsClamped() {
        var clock = FrameClock(maximumDelta: 0.25)
        _ = clock.tick(at: 10)
        #expect(clock.tick(at: 70) == 0.25)
    }

    /// После обрезанного кадра отсчёт продолжается от фактического времени, а
    /// не от «обрезанного»: следующая дельта снова нормальная, а не догоняющая.
    @Test("После обрезки часы идут от фактического времени")
    func resumesFromActualTimeAfterClamp() {
        var clock = FrameClock(maximumDelta: 0.25)
        _ = clock.tick(at: 10)
        _ = clock.tick(at: 70)
        #expect(clock.tick(at: 70.125) == 0.125)
    }

    @Test("Дельта ровно по потолку проходит целиком")
    func deltaAtLimitPassesThrough() {
        var clock = FrameClock(maximumDelta: 0.25)
        _ = clock.tick(at: 10)
        #expect(clock.tick(at: 10.25) == 0.25)
    }

    /// Часы, пошедшие назад, не должны двигать мир в обратную сторону.
    @Test("Отрицательная дельта превращается в ноль")
    func negativeDeltaBecomesZero() {
        var clock = FrameClock()
        _ = clock.tick(at: 10)
        #expect(clock.tick(at: 9) == 0)
    }

    @Test("По умолчанию потолок — 1/30 секунды")
    func defaultLimitIsThirtyFramesPerSecond() {
        var clock = FrameClock()
        _ = clock.tick(at: 10)
        #expect(clock.tick(at: 100) == FrameClock.defaultMaximumDelta)
    }
}
