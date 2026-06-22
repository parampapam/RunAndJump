//
//  GroundContactTrackerTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 22.06.2026.
//

import Testing
@testable import RunAndJump

struct GroundContactTrackerTests {

    @Test func notGroundedInitially() {
        let tracker = GroundContactTracker<String>()
        #expect(tracker.isGrounded == false)
    }

    @Test func groundedAfterAddingSupport() {
        var tracker = GroundContactTracker<String>()
        tracker.add("ground")
        #expect(tracker.isGrounded == true)
    }

    @Test func removingOnlySupportSignalsLeavingGround() {
        var tracker = GroundContactTracker<String>()
        tracker.add("ground")
        #expect(tracker.remove("ground") == true)
        #expect(tracker.isGrounded == false)
    }

    /// Главный сценарий бага: игрок стоит на земле, а подвижная платформа
    /// опускается сквозь него (контакт платформы начался и закончился). Пока
    /// земля остаётся опорой, отрыва от земли быть не должно — иначе прыжок
    /// пропадает навсегда.
    @Test func platformPassingThroughDoesNotLeaveGround() {
        var tracker = GroundContactTracker<String>()
        tracker.add("ground")

        tracker.add("platform")          // платформа вошла в игрока
        let leftGround = tracker.remove("platform")  // и вышла снизу

        #expect(leftGround == false)
        #expect(tracker.isGrounded == true)
    }

    @Test func leavesGroundOnlyWhenLastSupportRemoved() {
        var tracker = GroundContactTracker<String>()
        tracker.add("ground")
        tracker.add("platform")

        #expect(tracker.remove("ground") == false)   // ещё на платформе
        #expect(tracker.isGrounded == true)
        #expect(tracker.remove("platform") == true)  // опор не осталось
        #expect(tracker.isGrounded == false)
    }

    @Test func removingUnknownSupportIsNoTransition() {
        var tracker = GroundContactTracker<String>()
        tracker.add("ground")
        // Чужой/повторный remove не должен сигналить отрыв от земли.
        #expect(tracker.remove("platform") == false)
        #expect(tracker.isGrounded == true)
    }

    @Test func duplicateAddIsIdempotent() {
        var tracker = GroundContactTracker<String>()
        tracker.add("ground")
        tracker.add("ground")
        // Один remove убирает единственную (дедуплицированную) опору.
        #expect(tracker.remove("ground") == true)
        #expect(tracker.isGrounded == false)
    }
}
