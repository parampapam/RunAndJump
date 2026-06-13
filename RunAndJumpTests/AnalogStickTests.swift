//
//  AnalogStickTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
@testable import RunAndJump

@Suite("AnalogStick")
struct AnalogStickTests {

    private let accuracy: CGFloat = 0.0001

    private func isClose(_ a: CGFloat, _ b: CGFloat) -> Bool {
        abs(a - b) <= accuracy
    }

    // MARK: - direction

    @Test("Нулевое отклонение — нейтраль")
    func zeroOffsetIsNeutral() {
        let stick = AnalogStick(radius: 100, deadZone: 0.15)
        #expect(stick.direction(for: .zero) == .zero)
    }

    @Test("Отклонение внутри мёртвой зоны — нейтраль")
    func insideDeadZoneIsNeutral() {
        let stick = AnalogStick(radius: 100, deadZone: 0.2)
        // 10 точек из 100 = 0.1 < 0.2 — мёртвая зона.
        #expect(stick.direction(for: CGVector(dx: 10, dy: 0)) == .zero)
    }

    @Test("Полное отклонение по краю даёт модуль 1")
    func fullDeflectionGivesUnitMagnitude() {
        let stick = AnalogStick(radius: 100, deadZone: 0.2)
        let dir = stick.direction(for: CGVector(dx: 100, dy: 0))
        #expect(isClose(dir.dx, 1))
        #expect(isClose(dir.dy, 0))
    }

    @Test("Отклонение за край ограничено модулем 1")
    func beyondEdgeIsClampedToUnit() {
        let stick = AnalogStick(radius: 100, deadZone: 0.2)
        let dir = stick.direction(for: CGVector(dx: 250, dy: 0))
        #expect(isClose(dir.dx, 1))
    }

    @Test("Знак направления сохраняется")
    func signIsPreserved() {
        let stick = AnalogStick(radius: 100, deadZone: 0.2)
        let dir = stick.direction(for: CGVector(dx: -100, dy: 0))
        #expect(isClose(dir.dx, -1))
    }

    @Test("Частичное отклонение даёт промежуточную, перемасштабированную магнитуду")
    func partialDeflectionRescalesMagnitude() {
        let stick = AnalogStick(radius: 100, deadZone: 0.2)
        // normMag = 0.6; за вычетом мёртвой зоны: (0.6 - 0.2) / (1 - 0.2) = 0.5
        let dir = stick.direction(for: CGVector(dx: 60, dy: 0))
        #expect(isClose(dir.dx, 0.5))
    }

    @Test("По диагонали модуль не превышает 1")
    func diagonalDoesNotExceedUnit() {
        let stick = AnalogStick(radius: 100, deadZone: 0)
        // Угол стика: смещение (100,100), дистанция ~141 > радиус 100.
        let dir = stick.direction(for: CGVector(dx: 100, dy: 100))
        let magnitude = hypot(dir.dx, dir.dy)
        #expect(magnitude <= 1 + accuracy)
        #expect(isClose(magnitude, 1))
        // Направление — ровно по диагонали.
        #expect(isClose(dir.dx, dir.dy))
    }

    @Test("Ось Y положительна вверх (как в сцене)")
    func positiveYIsUp() {
        let stick = AnalogStick(radius: 100, deadZone: 0.1)
        let dir = stick.direction(for: CGVector(dx: 0, dy: 100))
        #expect(dir.dy > 0)
    }

    // MARK: - knobOffset

    @Test("Шляпка внутри радиуса следует за пальцем")
    func knobFollowsFingerInsideRadius() {
        let stick = AnalogStick(radius: 100, deadZone: 0.15)
        let offset = CGVector(dx: 30, dy: 40)   // дистанция 50 < 100
        let knob = stick.knobOffset(for: offset)
        #expect(isClose(knob.dx, 30))
        #expect(isClose(knob.dy, 40))
    }

    @Test("Шляпка за пределами радиуса прижата к окружности")
    func knobClampedToRadius() {
        let stick = AnalogStick(radius: 100, deadZone: 0.15)
        let offset = CGVector(dx: 300, dy: 400)   // дистанция 500
        let knob = stick.knobOffset(for: offset)
        // Прижато к радиусу 100 вдоль того же направления (60, 80).
        #expect(isClose(knob.dx, 60))
        #expect(isClose(knob.dy, 80))
        #expect(isClose(hypot(knob.dx, knob.dy), 100))
    }
}
