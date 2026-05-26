//
//  LadderControllerTests.swift
//  RunAndJumpTests
//

import Testing
@testable import RunAndJump
import CoreFoundation

@Suite("LadderController")
struct LadderControllerTests {

    @Test("По умолчанию — idle")
    func defaultIsIdle() {
        var controller = LadderController()
        #expect(controller.update() == .idle)
    }

    @Test("Касание лестницы без ввода — idle")
    func touchingLadderWithoutInputStaysIdle() {
        var controller = LadderController()
        controller.didTouchLadder()
        #expect(controller.update() == .idle)
    }

    @Test("Касание + нажатие вверх — startClimbing")
    func touchPlusUpStartsClimbing() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.didPressUp()
        #expect(controller.update() == .startClimbing)
        #expect(controller.isClimbing == true)
    }

    @Test("Касание + нажатие вниз — startClimbing")
    func touchPlusDownStartsClimbing() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.didPressDown()
        #expect(controller.update() == .startClimbing)
    }

    @Test("После начала лазания: вверх даёт положительную скорость")
    func climbUpProducesPositiveVelocity() {
        var controller = LadderController()
        controller.climbSpeed = 100
        controller.didTouchLadder()
        controller.didPressUp()
        _ = controller.update()  // startClimbing

        #expect(controller.update() == .climb(verticalVelocity: 100))
    }

    @Test("После начала лазания: вниз даёт отрицательную скорость")
    func climbDownProducesNegativeVelocity() {
        var controller = LadderController()
        controller.climbSpeed = 100
        controller.didTouchLadder()
        controller.didPressDown()
        _ = controller.update()

        #expect(controller.update() == .climb(verticalVelocity: -100))
    }

    @Test("На лестнице без ввода — висим (скорость 0)")
    func hangOnLadder() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.didPressUp()
        _ = controller.update()  // startClimbing

        controller.didReleaseVertical()
        #expect(controller.update() == .climb(verticalVelocity: 0))
    }

    @Test("Слез с лестницы — releaseLadder")
    func releaseWhenNoLongerTouching() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.didPressUp()
        _ = controller.update()  // startClimbing

        controller.didLeaveLadder()
        #expect(controller.update() == .releaseLadder)
        #expect(controller.isClimbing == false)
    }

    @Test("Прыжок с лестницы сбрасывает состояние climbing")
    func jumpOffLadderResetsState() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.didPressUp()
        _ = controller.update()  // startClimbing
        #expect(controller.isClimbing == true)

        controller.didJumpOffLadder()
        #expect(controller.isClimbing == false)
    }

    @Test("Касание лестницы во время полёта без ввода — idle, не цепляемся")
    func touchingMidJumpDoesNotAutoGrab() {
        var controller = LadderController()
        // Игрок прыгнул и пролетает сквозь лестницу, не нажимая вверх/вниз
        controller.didTouchLadder()
        #expect(controller.update() == .idle)
        #expect(controller.isClimbing == false)
    }
}
