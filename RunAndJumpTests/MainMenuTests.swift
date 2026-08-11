//
//  MainMenuTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 11.08.2026.
//

import Testing
@testable import RunAndJump

struct MainMenuTests {

    /// Порядок пунктов постоянный: он не зависит ни от сохранения, ни от того,
    /// какие разделы уже готовы, — кнопка не должна «переезжать» между запусками.
    /// Сверху продолжение начатой партии: за ним в меню возвращаются чаще всего.
    @Test func offersSameItemsInSameOrder() {
        for hasSavedGame in [true, false] {
            #expect(MainMenu.items(hasSavedGame: hasSavedGame).map(\.action)
                    == [.continueGame, .newGame, .settings, .about])
        }
    }

    @Test func everyActionIsOfferedByTheMenu() {
        let offered = Set(MainMenu.items(hasSavedGame: true).map(\.action))
        #expect(offered == Set(MainMenuAction.allCases))
    }

    @Test func everyItemHasATitle() {
        for hasSavedGame in [true, false] {
            #expect(MainMenu.items(hasSavedGame: hasSavedGame).allSatisfy { !$0.title.isEmpty })
        }
    }

    /// «Продолжить» доступно ровно тогда, когда есть что продолжать: пункт,
    /// ведущий в несуществующую партию, врал бы игроку.
    @Test func continueIsEnabledOnlyWithASavedGame() throws {
        #expect(try item(.continueGame, hasSavedGame: true).isEnabled)
        #expect(try !item(.continueGame, hasSavedGame: false).isEnabled)
    }

    /// Недоступный пункт не исчезает — иначе остальные съезжали бы вверх.
    @Test func continueStaysVisibleWithoutASavedGame() {
        #expect(MainMenu.items(hasSavedGame: false).count
                == MainMenu.items(hasSavedGame: true).count)
    }

    /// Новую игру можно начать всегда — это единственный выход с экрана после
    /// первой установки.
    @Test func newGameIsAlwaysEnabled() throws {
        for hasSavedGame in [true, false] {
            #expect(try item(.newGame, hasSavedGame: hasSavedGame).isEnabled)
        }
    }

    /// Разделы, экранов которых ещё нет, выключены: нажимаемая кнопка, не
    /// делающая ничего, читается как поломка.
    @Test func unimplementedSectionsAreDisabled() throws {
        for action: MainMenuAction in [.settings, .about] {
            #expect(try !item(action, hasSavedGame: true).isEnabled)
        }
    }

    /// Главное действие на экране ровно одно: два акцента спорили бы друг с
    /// другом, ноль — оставили бы экран без очевидного следующего шага.
    @Test func exactlyOneItemIsPrimary() {
        for hasSavedGame in [true, false] {
            #expect(MainMenu.items(hasSavedGame: hasSavedGame).filter(\.isPrimary).count == 1)
        }
    }

    /// Выделен всегда доступный пункт: подсвеченная погашенная кнопка — это
    /// приглашение нажать то, что не нажимается.
    @Test func primaryItemIsAlwaysEnabled() {
        for hasSavedGame in [true, false] {
            #expect(MainMenu.items(hasSavedGame: hasSavedGame)
                .allSatisfy { !$0.isPrimary || $0.isEnabled })
        }
    }

    /// Акцент идёт за первым доступным пунктом: есть сохранение — продолжаем,
    /// нет — начинаем заново.
    @Test func primaryFollowsTheSavedGame() throws {
        #expect(try item(.continueGame, hasSavedGame: true).isPrimary)
        #expect(try item(.newGame, hasSavedGame: false).isPrimary)
    }

    // MARK: - Helpers

    private func item(_ action: MainMenuAction, hasSavedGame: Bool) throws -> MainMenuItem {
        try #require(MainMenu.items(hasSavedGame: hasSavedGame).first { $0.action == action })
    }
}
