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
    /// же порядке: кнопка не должна «переезжать» между открытиями окна.
    @Test func offersSameThreeActionsInOrder() {
        #expect(PauseMenu.items.map(\.action) == [.resume, .restartLevel, .mainMenu])
    }

    @Test func everyActionIsOfferedByTheMenu() {
        #expect(Set(PauseMenu.items.map(\.action)) == Set(PauseMenuAction.allCases))
    }

    @Test func everyItemHasATitle() {
        #expect(PauseMenu.items.allSatisfy { !$0.title.isEmpty })
    }

    @Test func windowHasATitle() {
        #expect(!PauseMenu.title.isEmpty)
    }
}
