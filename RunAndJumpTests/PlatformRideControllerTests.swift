//
//  PlatformRideControllerTests.swift
//  RunAndJumpTests
//

import Testing
@testable import RunAndJump
import CoreGraphics

@Suite("PlatformRideController")
struct PlatformRideControllerTests {

    // Общая геометрия для тестов: платформа 100x20 в (0, 0), игрок 32x32.
    private let platformSize = CGSize(width: 100, height: 20)
    private let playerSize = CGSize(width: 32, height: 32)

    // Y, на котором низ игрока ровно на верхнем ребре платформы в (0, 0).
    private var restingPlayerY: CGFloat {
        platformSize.height / 2 + playerSize.height / 2  // 10 + 16 = 26
    }

    @Test("По умолчанию — не едет, resolveRide возвращает idle")
    func defaultIsIdle() {
        var controller = PlatformRideController()
        #expect(controller.isRiding == false)
        let action = controller.resolveRide(
            platformPosition: .zero,
            playerPosition: .zero,
            playerSize: playerSize,
            horizontalInputVelocity: 0,
            dt: 0.016
        )
        #expect(action == .idle)
    }

    @Test("Приземление сверху — привязка состоялась")
    func attachFromAbove() {
        var controller = PlatformRideController()
        let attached = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 5, y: restingPlayerY),
            playerSize: playerSize,
            at: 1.0
        )
        #expect(attached == true)
        #expect(controller.isRiding == true)
    }

    @Test("Удар снизу — привязки нет")
    func noAttachFromBelow() {
        var controller = PlatformRideController()
        // Игрок врезается в платформу снизу: его центр сильно ниже ребра.
        let attached = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 0, y: -40),
            playerSize: playerSize,
            at: 1.0
        )
        #expect(attached == false)
        #expect(controller.isRiding == false)
    }

    @Test("Сразу после прыжка привязка запрещена кулдауном")
    func attachBlockedRightAfterJump() {
        var controller = PlatformRideController()
        controller.attachCooldownAfterJump = 0.25
        controller.didJump(at: 1.0)

        // Контакт почти сразу после прыжка — в пределах кулдауна.
        let attached = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 0, y: restingPlayerY),
            playerSize: playerSize,
            at: 1.1
        )
        #expect(attached == false)
    }

    @Test("После истечения кулдауна привязка снова возможна")
    func attachAllowedAfterCooldown() {
        var controller = PlatformRideController()
        controller.attachCooldownAfterJump = 0.25
        controller.didJump(at: 1.0)

        let attached = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 0, y: restingPlayerY),
            playerSize: playerSize,
            at: 1.3  // прошло 0.3 > 0.25
        )
        #expect(attached == true)
    }

    @Test("Без ввода игрок едет вместе с платформой")
    func ridesWithPlatformWithoutInput() {
        var controller = PlatformRideController()
        _ = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 5, y: restingPlayerY),
            playerSize: playerSize,
            at: 1.0
        )

        // Платформа сдвинулась на (30, 8). Игрок должен повторить ход, сохранив offset.
        let action = controller.resolveRide(
            platformPosition: CGPoint(x: 30, y: 8),
            playerPosition: CGPoint(x: 5, y: restingPlayerY),
            playerSize: playerSize,
            horizontalInputVelocity: 0,
            dt: 0.016
        )
        // offset был (5, 26) → target = платформа + offset.
        #expect(action == .ride(targetPosition: CGPoint(x: 35, y: 34)))
    }

    @Test("Ввод смещает игрока в системе отсчёта платформы (аддитивно)")
    func inputShiftsRiderAlongPlatform() {
        var controller = PlatformRideController()
        _ = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 0, y: restingPlayerY),
            playerSize: playerSize,
            at: 1.0
        )

        // Платформа на месте, игрок идёт вправо 100 pts/s за 0.1 с → +10 к offset.x.
        let action = controller.resolveRide(
            platformPosition: .zero,
            playerPosition: CGPoint(x: 0, y: restingPlayerY),
            playerSize: playerSize,
            horizontalInputVelocity: 100,
            dt: 0.1
        )
        #expect(action == .ride(targetPosition: CGPoint(x: 10, y: restingPlayerY)))
    }

    @Test("Препятствие на пути упирает игрока в свой бок")
    func obstacleBlocksHorizontalCarry() {
        var controller = PlatformRideController()
        // Неподвижная платформа-преграда: левый бок на x = 40, широкая и высокая,
        // чтобы игрок упёрся в бок, а не проскочил её насквозь.
        controller.obstacles = [
            CGRect(x: 40, y: 0, width: 100, height: 60)
        ]
        _ = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 0, y: 20),
            playerSize: playerSize,
            at: 1.0
        )

        // Игрок едет вправо так, что без преграды target.x ушёл бы за 40.
        let action = controller.resolveRide(
            platformPosition: .zero,
            playerPosition: CGPoint(x: 0, y: 20),
            playerSize: playerSize,
            horizontalInputVelocity: 1000,
            dt: 0.1  // +100 к offset.x → target.x = 100 без упора
        )
        // Упираемся боком игрока (halfW = 16) в левый край рамки (minX = 40): 40 - 16 = 24.
        guard case .ride(let target) = action else {
            Issue.record("ожидали .ride")
            return
        }
        #expect(target.x == 24)
    }

    @Test("Слез с платформы — снова idle")
    func leavingPlatformGoesIdle() {
        var controller = PlatformRideController()
        _ = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 0, y: restingPlayerY),
            playerSize: playerSize,
            at: 1.0
        )
        #expect(controller.isRiding == true)

        controller.didLeavePlatform()
        #expect(controller.isRiding == false)
        let action = controller.resolveRide(
            platformPosition: .zero,
            playerPosition: .zero,
            playerSize: playerSize,
            horizontalInputVelocity: 0,
            dt: 0.016
        )
        #expect(action == .idle)
    }

    @Test("Прыжок отрывает от платформы")
    func jumpDetachesFromPlatform() {
        var controller = PlatformRideController()
        _ = controller.tryAttach(
            platformPosition: .zero,
            platformSize: platformSize,
            playerPosition: CGPoint(x: 0, y: restingPlayerY),
            playerSize: playerSize,
            at: 1.0
        )
        #expect(controller.isRiding == true)

        controller.didJump(at: 2.0)
        #expect(controller.isRiding == false)
    }
}
