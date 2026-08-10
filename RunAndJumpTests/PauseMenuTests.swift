//
//  PauseMenuTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 10.08.2026.
//

import Testing
@testable import RunAndJump

struct PauseMenuTests {

    /// Окно паузы всегда предлагает одни и те же три действия — и в одном и том
    /// же порядке: кнопка не должна «переезжать» между запусками.
    @Test func offersSameThreeActionsInBothCases() {
        for reason: PauseReason in [.playerRequested, .resumedSession] {
            #expect(PauseMenu.items(for: reason).map(\.action) == [.resume, .restartLevel, .restartGame])
        }
    }

    @Test func everyActionIsOfferedByTheMenu() {
        let offered = Set(PauseMenu.items(for: .playerRequested).map(\.action))
        #expect(offered == Set(PauseMenuAction.allCases))
    }

    /// Продолжение прерванной партии значит не то же, что снятие обычной паузы,
    /// — окна должны отличаться словами.
    @Test func resumedSessionIsWordedDifferently() {
        #expect(PauseMenu.title(for: .resumedSession) != PauseMenu.title(for: .playerRequested))

        let resumeTitle: (PauseReason) -> String? = { reason in
            PauseMenu.items(for: reason).first { $0.action == .resume }?.title
        }
        #expect(resumeTitle(.resumedSession) != resumeTitle(.playerRequested))
    }

    /// Про точку восстановления игроку говорят только там, где это неочевидно:
    /// после закрытия приложения.
    @Test func onlyResumedSessionExplainsCheckpoint() {
        #expect(PauseMenu.message(for: .resumedSession) != nil)
        #expect(PauseMenu.message(for: .playerRequested) == nil)
    }

    @Test func everyItemHasATitle() {
        for reason: PauseReason in [.playerRequested, .resumedSession] {
            #expect(PauseMenu.items(for: reason).allSatisfy { !$0.title.isEmpty })
        }
    }
}
