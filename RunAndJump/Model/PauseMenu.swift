//
//  PauseMenu.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 10.08.2026.
//

import Foundation

/// Почему открыто окно паузы.
///
/// Действия в окне от причины не зависят — меняются только слова: игрок,
/// вернувшийся в игру через день, должен понимать, что «продолжить» вернёт его
/// не туда, где он бросил игру, а на последнюю точку восстановления.
enum PauseReason: Equatable {
    /// Уровень прерван посреди игры — кнопкой паузы или сворачиванием
    /// приложения. Сцена цела, уровень продолжится ровно с того же места,
    /// поэтому у обеих причин и слова одни и те же.
    case interrupted
    /// Партия открыта заново после выгрузки приложения. Положение игрока внутри
    /// уровня не сохраняется (см. `GameProgressStore`), поэтому продолжение —
    /// это возрождение на последнем поднятом флаге.
    case resumedSession
}

/// Что делает пункт окна паузы. Сама сцена решает, *как* это выполнить, но
/// набор возможных исходов задан здесь и покрыт тестами.
enum PauseMenuAction: Equatable, CaseIterable {
    /// Снять паузу и продолжить с текущего места (или с точки восстановления,
    /// если уровень только что собран из сохранения).
    case resume
    /// Начать текущий уровень с начала: флаги, награды и враги — как при первом
    /// входе на уровень (см. `GameProgressRules.levelRestarted`).
    case restartLevel
    /// Начать игру сначала: первый уровень, нулевой счёт, сохранение стирается.
    case restartGame
}

/// Пункт окна паузы: действие и подпись на кнопке.
struct PauseMenuItem: Equatable {
    let action: PauseMenuAction
    let title: String
}

/// Содержимое окна паузы — чистое сопоставление «причина → тексты и пункты».
/// Узел (`PauseMenuNode`) только рисует то, что здесь описано.
enum PauseMenu {

    static func title(for reason: PauseReason) -> String {
        switch reason {
        case .interrupted: return "Paused"
        case .resumedSession: return "Welcome back"
        }
    }

    /// Пояснение под заголовком; `nil` — пояснять нечего.
    /// Есть только у возобновлённой партии: там «продолжить» значит не то же
    /// самое, что при обычной паузе.
    static func message(for reason: PauseReason) -> String? {
        switch reason {
        case .interrupted: return nil
        case .resumedSession: return "You will continue from the last checkpoint"
        }
    }

    /// Пункты сверху вниз. Порядок один и тот же в обоих случаях: место кнопки
    /// не должно «переезжать» между запусками.
    static func items(for reason: PauseReason) -> [PauseMenuItem] {
        [
            PauseMenuItem(action: .resume, title: resumeTitle(for: reason)),
            PauseMenuItem(action: .restartLevel, title: "Restart level"),
            PauseMenuItem(action: .restartGame, title: "New game"),
        ]
    }

    private static func resumeTitle(for reason: PauseReason) -> String {
        switch reason {
        case .interrupted: return "Resume"
        case .resumedSession: return "Continue"
        }
    }
}
