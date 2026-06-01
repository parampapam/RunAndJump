//
//  FrameClockTests.swift
//  RunAndJumpTests
//

import Testing
@testable import RunAndJump
import Foundation

@Suite("FrameClock")
struct FrameClockTests {

    @Test("Первый кадр только фиксирует время и возвращает nil")
    func firstTickReturnsNil() {
        var clock = FrameClock()
        #expect(clock.tick(at: 10) == nil)
    }

    @Test("Со второго кадра возвращает дельту с прошлого")
    func returnsDeltaAfterFirst() {
        var clock = FrameClock()
        _ = clock.tick(at: 10)
        #expect(clock.tick(at: 10.5) == 0.5)
        #expect(clock.tick(at: 12) == 1.5)
    }

    @Test("Одинаковая метка времени даёт нулевую дельту")
    func sameTimeYieldsZero() {
        var clock = FrameClock()
        _ = clock.tick(at: 10)
        #expect(clock.tick(at: 10) == 0)
    }
}
