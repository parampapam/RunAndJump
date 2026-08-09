//
//  UserDefaultsProgressStore.swift
//  RunAndJump
//

import Foundation

/// Прогресс в `UserDefaults` — одним JSON-значением под одним ключом.
///
/// `UserDefaults`, а не файл: объём — десятки байт, запись синхронная и
/// дешёвая, а система сама сбрасывает её на диск при уходе в фон. Именно это
/// нам и нужно: сохранение случается в момент игрового события (флаг, гибель,
/// конец уровня), а не по сигналу жизненного цикла, который свёрнутое
/// приложение может уже не получить перед выгрузкой из памяти.
struct UserDefaultsProgressStore: GameProgressStore {

    /// Версия в ключе — чтобы несовместимое сохранение от старой сборки просто
    /// не нашлось, а не разбиралось с ошибкой.
    private let key = "game.progress.v1"

    private let defaults: UserDefaults

    /// `defaults` инжектируется, чтобы тест писал в свою песочницу
    /// (`UserDefaults(suiteName:)`), а не в настройки приложения.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GameProgress? {
        guard let data = defaults.data(forKey: key) else { return nil }
        // Битое или устаревшее сохранение — это «сохранения нет»: игра начнётся
        // сначала, но точно не упадёт на запуске.
        return try? JSONDecoder().decode(GameProgress.self, from: data)
    }

    func save(_ progress: GameProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
