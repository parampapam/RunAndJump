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
        controller.setVerticalInput(1)
        #expect(controller.update() == .startClimbing)
        #expect(controller.isClimbing == true)
    }

    @Test("Лёгкий вертикальный дрейф при ходьбе вбок не цепляет к лестнице")
    func smallVerticalDriftDoesNotStartClimbing() {
        var controller = LadderController()
        controller.didTouchLadder()
        // Идём вбок, держа стик вправо: вертикаль чуть дрожит, но порог не пройден.
        controller.setVerticalInput(0.2)
        #expect(controller.update() == .idle)
        #expect(controller.isClimbing == false)
    }

    @Test("Касание + нажатие вниз — startClimbing")
    func touchPlusDownStartsClimbing() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.setVerticalInput(-1)
        #expect(controller.update() == .startClimbing)
    }

    @Test("После начала лазания: вверх даёт положительную скорость")
    func climbUpProducesPositiveVelocity() {
        var controller = LadderController()
        controller.climbSpeed = 100
        controller.didTouchLadder()
        controller.setVerticalInput(1)
        _ = controller.update()  // startClimbing

        #expect(controller.update() == .climb(verticalVelocity: 100))
    }

    @Test("После начала лазания: вниз даёт отрицательную скорость")
    func climbDownProducesNegativeVelocity() {
        var controller = LadderController()
        controller.climbSpeed = 100
        controller.didTouchLadder()
        controller.setVerticalInput(-1)
        _ = controller.update()

        #expect(controller.update() == .climb(verticalVelocity: -100))
    }

    @Test("Частичное отклонение даёт частичную скорость лазания")
    func partialVerticalInputScalesClimbSpeed() {
        var controller = LadderController()
        controller.climbSpeed = 100
        controller.didTouchLadder()
        controller.setVerticalInput(0.5)
        _ = controller.update()  // startClimbing

        #expect(controller.update() == .climb(verticalVelocity: 50))
    }

    @Test("На лестнице без ввода — висим (скорость 0)")
    func hangOnLadder() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.setVerticalInput(1)
        _ = controller.update()  // startClimbing

        controller.setVerticalInput(0)
        #expect(controller.update() == .climb(verticalVelocity: 0))
    }

    @Test("Спуск до земли отпускает лестницу")
    func reachingGroundWhileClimbingReleases() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.setVerticalInput(-1)   // лезем вниз (в воздухе)
        _ = controller.update()           // startClimbing
        #expect(controller.isClimbing == true)

        controller.didTouchGround()       // упёрлись в землю
        #expect(controller.update() == .releaseLadder)
        #expect(controller.isClimbing == false)
    }

    @Test("На земле толчок вниз у лестницы не цепляет — некуда спускаться")
    func pushingDownOnGroundDoesNotAttach() {
        var controller = LadderController()
        controller.didTouchGround()
        controller.didTouchLadder()
        controller.setVerticalInput(-1)
        #expect(controller.update() == .idle)
        #expect(controller.isClimbing == false)
    }

    @Test("С земли толчок вверх цепляет за лестницу")
    func pushingUpFromGroundAttaches() {
        var controller = LadderController()
        controller.didTouchGround()
        controller.didTouchLadder()
        controller.setVerticalInput(1)
        #expect(controller.update() == .startClimbing)
        #expect(controller.isClimbing == true)
    }

    @Test("Подъём с земли не отцепляется сразу, пока ещё на земле")
    func climbingUpFromGroundDoesNotReleaseWhileGrounded() {
        var controller = LadderController()
        controller.climbSpeed = 120
        controller.didTouchGround()
        controller.didTouchLadder()
        controller.setVerticalInput(1)
        #expect(controller.update() == .startClimbing)
        // Первый кадр подъёма — всё ещё на земле, но лезем вверх: не отцепляемся.
        #expect(controller.update() == .climb(verticalVelocity: 120))
    }

    @Test("Слез с лестницы — releaseLadder")
    func releaseWhenNoLongerTouching() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.setVerticalInput(1)
        _ = controller.update()  // startClimbing

        controller.didLeaveLadder()
        #expect(controller.update() == .releaseLadder)
        #expect(controller.isClimbing == false)
    }

    @Test("Прыжок с лестницы сбрасывает состояние climbing")
    func jumpOffLadderResetsState() {
        var controller = LadderController()
        controller.didTouchLadder()
        controller.setVerticalInput(1)
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
