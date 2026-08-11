//
//  MainMenu.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 11.08.2026.
//

import Foundation

/// Что делает пункт главного меню. Как именно — решает сцена, но набор
/// возможных исходов задан здесь и покрыт тестами.
enum MainMenuAction: Equatable, CaseIterable {
    /// Начать заново с первого уровня; сохранение стирается.
    case newGame
    /// Вернуться в сохранённую партию — на последнюю поднятую точку
    /// восстановления (положение внутри уровня не сохраняется,
    /// см. `GameProgressStore`).
    case continueGame
    /// Настройки игры.
    case settings
    /// Об игре.
    case about
}

/// Пункт главного меню: действие, подпись, доступность и роль на экране.
struct MainMenuItem: Equatable {
    let action: MainMenuAction
    let title: String
    /// Недоступный пункт виден, но не нажимается: место кнопки не должно
    /// «переезжать» между запусками, поэтому мы гасим её, а не прячем.
    let isEnabled: Bool
    /// Главное действие экрана — то, ради которого игрок сюда и пришёл.
    /// Ровно одно на меню; узел выделяет его цветом.
    let isPrimary: Bool
}

/// Содержимое главного меню — чистое сопоставление «есть ли сохранение → пункты».
/// Сцена (`MainMenuScene`) только рисует то, что здесь описано.
enum MainMenu {

    static let title = "Run and Jump"

    /// Пункты сверху вниз. Порядок постоянный: он не зависит ни от сохранения,
    /// ни от того, какие разделы уже готовы. Сверху — продолжение начатой партии:
    /// в меню чаще всего возвращаются именно за ним.
    ///
    /// Выделение цветом идёт за первым **доступным** пунктом, а не приколочено к
    /// одному действию: без сохранения продолжать нечего, и подсвеченной осталась
    /// бы погашенная кнопка, а экран — без главного действия вовсе.
    ///
    /// - Parameter hasSavedGame: есть ли партия, которую можно продолжить.
    ///   Отвечает на это `GameProgressRules.isResumable` — меню само сохранение
    ///   не разбирает.
    static func items(hasSavedGame: Bool) -> [MainMenuItem] {
        [
            // Продолжать нечего — пункт гаснет: предлагать игроку вход в партию,
            // которой нет, значит врать ему.
            MainMenuItem(action: .continueGame, title: "Continue",
                         isEnabled: hasSavedGame, isPrimary: hasSavedGame),
            MainMenuItem(action: .newGame, title: "New Game",
                         isEnabled: true, isPrimary: !hasSavedGame),
            // Экранов этих разделов ещё нет. Готовый раздел = `isEnabled: true`
            // здесь плюс его случай в `MainMenuScene.handle(_:)`.
            MainMenuItem(action: .settings, title: "Settings",
                         isEnabled: false, isPrimary: false),
            MainMenuItem(action: .about, title: "About",
                         isEnabled: false, isPrimary: false),
        ]
    }
}
