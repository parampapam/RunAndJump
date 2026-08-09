//
//  GameProgressStore.swift
//  RunAndJump
//

import Foundation

/// Хранилище прогресса между запусками приложения.
///
/// Отдельный протокол, а не прямой вызов `UserDefaults` из сцены: сохранение —
/// это ввод-вывод, а он в этом проекте живёт на краю. Сцена знает только
/// «сохранить/загрузить/забыть», подставить сюда можно что угодно — файл,
/// iCloud, пустышку в тестах.
protocol GameProgressStore {

    /// Сохранённый прогресс либо `nil`, если сохранения нет или оно нечитаемо.
    /// Решение, годится ли прочитанное для текущей сборки, принимает
    /// `GameProgressRules.resumable` — хранилище само ничего не валидирует.
    func load() -> GameProgress?

    /// Записывает прогресс поверх предыдущего.
    func save(_ progress: GameProgress)

    /// Забывает сохранение: следующий запуск начнётся с первого уровня.
    func clear()
}

/// Хранилище, которое ничего не хранит. Для превью и любого места, где
/// сохранение только мешает.
struct NullProgressStore: GameProgressStore {
    func load() -> GameProgress? { nil }
    func save(_ progress: GameProgress) {}
    func clear() {}
}
