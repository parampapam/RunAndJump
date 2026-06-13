//
//  LadderControllerTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
@testable import RunAndJump

@Suite("LadderController")
struct LadderControllerTests {

    /// Условные координаты для тестов: основание лестницы (верх опоры — земли
    /// или платформы) и положение «высоко на лестнице» (ступни много выше низа).
    let ladderBottom: CGFloat = 100
    let highOnLadder: CGFloat = 300

    @Test("По умолчанию — idle")
    func defaultIsIdle() {
        var controller = LadderController()
        #expect(controller.update(playerFeetY: highOnLadder) == .idle)
    }

    @Test("Касание лестницы без ввода — idle")
    func touchingLadderWithoutInputStaysIdle() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        #expect(controller.update(playerFeetY: highOnLadder) == .idle)
    }

    @Test("Касание + нажатие вверх — startClimbing")
    func touchPlusUpStartsClimbing() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(1)
        #expect(controller.update(playerFeetY: highOnLadder) == .startClimbing)
        #expect(controller.isClimbing == true)
    }

    @Test("Лёгкий вертикальный дрейф при ходьбе вбок не цепляет к лестнице")
    func smallVerticalDriftDoesNotStartClimbing() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        // Идём вбок, держа стик вправо: вертикаль чуть дрожит, но порог не пройден.
        controller.setVerticalInput(0.2)
        #expect(controller.update(playerFeetY: highOnLadder) == .idle)
        #expect(controller.isClimbing == false)
    }

    @Test("Касание + нажатие вниз (в воздухе) — startClimbing")
    func touchPlusDownStartsClimbing() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(-1)
        #expect(controller.update(playerFeetY: highOnLadder) == .startClimbing)
    }

    @Test("После начала лазания: вверх даёт положительную скорость")
    func climbUpProducesPositiveVelocity() {
        var controller = LadderController()
        controller.climbSpeed = 100
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(1)
        _ = controller.update(playerFeetY: highOnLadder)  // startClimbing

        #expect(controller.update(playerFeetY: highOnLadder) == .climb(verticalVelocity: 100))
    }

    @Test("После начала лазания: вниз даёт отрицательную скорость")
    func climbDownProducesNegativeVelocity() {
        var controller = LadderController()
        controller.climbSpeed = 100
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(-1)
        _ = controller.update(playerFeetY: highOnLadder)  // startClimbing

        // Ступни ещё выше основания — продолжаем спускаться, не отцепляемся.
        #expect(controller.update(playerFeetY: 250) == .climb(verticalVelocity: -100))
    }

    @Test("Частичное отклонение даёт частичную скорость лазания")
    func partialVerticalInputScalesClimbSpeed() {
        var controller = LadderController()
        controller.climbSpeed = 100
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(0.5)
        _ = controller.update(playerFeetY: highOnLadder)  // startClimbing

        #expect(controller.update(playerFeetY: highOnLadder) == .climb(verticalVelocity: 50))
    }

    @Test("На лестнице без ввода — висим (скорость 0)")
    func hangOnLadder() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(1)
        _ = controller.update(playerFeetY: highOnLadder)  // startClimbing

        controller.setVerticalInput(0)
        #expect(controller.update(playerFeetY: highOnLadder) == .climb(verticalVelocity: 0))
    }

    @Test("Спуск до основания лестницы отпускает её")
    func reachingBottomWhileClimbingReleases() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(-1)                   // лезем вниз
        _ = controller.update(playerFeetY: highOnLadder)  // startClimbing
        #expect(controller.isClimbing == true)

        // Ступни дошли до основания — отцепляемся (встаём на опору).
        #expect(controller.update(playerFeetY: ladderBottom) == .releaseLadder)
        #expect(controller.isClimbing == false)
    }

    @Test("Спуск на платформу (основание выше земли) тоже отпускает лестницу")
    func descendingToPlatformReleases() {
        var controller = LadderController()
        // Лестница «платформа → платформа»: её основание — верх нижней платформы.
        let platformTop: CGFloat = 250
        controller.didTouchLadder(bottomY: platformTop)
        controller.setVerticalInput(-1)
        _ = controller.update(playerFeetY: 420)  // startClimbing, высоко на лестнице

        // На полпути, выше платформы — продолжаем спуск, не отцепляемся раньше времени.
        #expect(controller.update(playerFeetY: 330) == .climb(verticalVelocity: -120))
        // Дошли до платформы — отцепляемся и встаём на неё.
        #expect(controller.update(playerFeetY: platformTop) == .releaseLadder)
        #expect(controller.isClimbing == false)
    }

    @Test("У основания толчок вниз не цепляет — спускаться некуда")
    func pushingDownAtBottomDoesNotAttach() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(-1)
        #expect(controller.update(playerFeetY: ladderBottom) == .idle)
        #expect(controller.isClimbing == false)
    }

    @Test("От основания толчок вверх цепляет за лестницу")
    func pushingUpFromBottomAttaches() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(1)
        #expect(controller.update(playerFeetY: ladderBottom) == .startClimbing)
        #expect(controller.isClimbing == true)
    }

    @Test("Подъём от основания не отцепляется сразу, пока ступни ещё внизу")
    func climbingUpFromBottomDoesNotReleaseWhileAtBottom() {
        var controller = LadderController()
        controller.climbSpeed = 120
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(1)
        #expect(controller.update(playerFeetY: ladderBottom) == .startClimbing)
        // Первый кадр подъёма — ступни ещё у основания, но лезем вверх: не отцепляемся.
        #expect(controller.update(playerFeetY: ladderBottom) == .climb(verticalVelocity: 120))
    }

    @Test("Слез сверху (потеряли контакт) — releaseLadder")
    func releaseWhenNoLongerTouching() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(1)
        _ = controller.update(playerFeetY: highOnLadder)  // startClimbing

        controller.didLeaveLadder()
        #expect(controller.update(playerFeetY: highOnLadder) == .releaseLadder)
        #expect(controller.isClimbing == false)
    }

    @Test("Прыжок с лестницы сбрасывает состояние climbing")
    func jumpOffLadderResetsState() {
        var controller = LadderController()
        controller.didTouchLadder(bottomY: ladderBottom)
        controller.setVerticalInput(1)
        _ = controller.update(playerFeetY: highOnLadder)  // startClimbing
        #expect(controller.isClimbing == true)

        controller.didJumpOffLadder()
        #expect(controller.isClimbing == false)
    }

    @Test("Касание лестницы во время полёта без ввода — idle, не цепляемся")
    func touchingMidJumpDoesNotAutoGrab() {
        var controller = LadderController()
        // Игрок прыгнул и пролетает сквозь лестницу, не нажимая вверх/вниз
        controller.didTouchLadder(bottomY: ladderBottom)
        #expect(controller.update(playerFeetY: highOnLadder) == .idle)
        #expect(controller.isClimbing == false)
    }
}
