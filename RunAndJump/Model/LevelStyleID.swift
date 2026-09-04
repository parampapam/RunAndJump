//
//  LevelStyleID.swift
//  RunAndJump
//

import Foundation

/// Идентификатор стиля уровня — набора текстур ландшафта, фона и декораций.
/// Открытый по той же причине, что и `DecorationID`: код на стиле не ветвится,
/// от него зависит только то, чем нарисован уровень.
///
/// Стиль есть у ландшафта, фона и декораций. У игрока, врагов, наград и HUD
/// стиля **нет** — их атласы общие на всю игру. Граница проведена намеренно:
/// иначе к третьему стилю пришлось бы рисовать своего игрока каждому.
struct LevelStyleID: RawRepresentable, Hashable, Sendable {

    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Луг — стиль, в котором собраны все нынешние уровни.
    static let grassland = LevelStyleID("grassland")
}
