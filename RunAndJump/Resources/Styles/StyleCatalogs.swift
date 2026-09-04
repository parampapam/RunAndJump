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
}
