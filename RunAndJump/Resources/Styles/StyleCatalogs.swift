//
//  StyleCatalogs.swift
//  RunAndJump
//

import Foundation

/// Все стили, которые знает игра. Единственное место, где идентификатор стиля
/// превращается в каталог: сцена спрашивает каталог по `LevelConfiguration.style`,
/// а тесты проходят по `all` и проверяют каждый.
enum StyleCatalogs {

    static let all: [StyleCatalog] = [GrasslandCatalog.catalog]

    /// Каталог стиля; `nil` — такого стиля нет.
    static func catalog(for id: LevelStyleID) -> StyleCatalog? {
        all.first { $0.id == id }
    }

    /// Каталог для сборки уровня. Неизвестный стиль — не ситуация у игрока, а
    /// баг сборки: стили и уровни свои, из бандла, и обновляются вместе с кодом.
    /// Поэтому в DEBUG падаем сразу, а в релизе рисуем первым известным стилем —
    /// уровень терять из-за опечатки в поле нельзя.
    static func resolved(_ id: LevelStyleID) -> StyleCatalog {
        if let catalog = catalog(for: id) { return catalog }
        assertionFailure("Неизвестный стиль уровня: \(id.rawValue)")
        return GrasslandCatalog.catalog
    }
}
