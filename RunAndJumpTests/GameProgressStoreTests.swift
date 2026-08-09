//
//  GameProgressStoreTests.swift
//  RunAndJumpTests
//

import Foundation
import Testing
@testable import RunAndJump

@Suite("Сохранение прогресса между запусками")
struct GameProgressStoreTests {

    private static let saved = GameProgress(
        currentLevelIndex: 1,
        carriedBonusPoints: 75,
        activeCheckpointIndex: 2,
        collectedPickupIndices: [0, 3, 4],
        defeatedEnemyIndices: [1, 2]
    )

    /// Своя песочница на каждый тест — чтобы не задеть настройки приложения
    /// и чтобы тесты не мешали друг другу.
    private func makeStore() -> (UserDefaultsProgressStore, UserDefaults) {
        let suite = "GameProgressStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (UserDefaultsProgressStore(defaults: defaults), defaults)
    }

    // MARK: - Хранилище

    @Test("Сохранённый прогресс читается целиком")
    func roundTripKeepsEveryField() throws {
        let (store, _) = makeStore()

        store.save(Self.saved)
        let loaded = try #require(store.load())

        #expect(loaded == Self.saved)
    }

    @Test("Пустое хранилище отдаёт nil")
    func emptyStoreLoadsNil() {
        let (store, _) = makeStore()
        #expect(store.load() == nil)
    }

    @Test("Повторное сохранение перезаписывает прежнее")
    func saveOverwrites() throws {
        let (store, _) = makeStore()

        store.save(Self.saved)
        store.save(GameProgress(currentLevelIndex: 2, carriedBonusPoints: 120))

        let loaded = try #require(store.load())
        #expect(loaded.currentLevelIndex == 2)
        #expect(loaded.carriedBonusPoints == 120)
        #expect(loaded.collectedPickupIndices.isEmpty)
    }

    @Test("Очистка возвращает состояние «сохранения нет»")
    func clearRemovesSave() {
        let (store, _) = makeStore()

        store.save(Self.saved)
        store.clear()

        #expect(store.load() == nil)
    }

    /// Сохранение от несовместимой сборки не должно ронять запуск: битые
    /// данные — это просто «сохранения нет».
    @Test("Нечитаемые данные трактуются как отсутствие сохранения")
    func corruptedDataLoadsNil() {
        let (store, defaults) = makeStore()

        store.save(Self.saved)
        defaults.set(Data("не JSON".utf8), forKey: "game.progress.v1")

        #expect(store.load() == nil)
    }

    @Test("Пустышка ничего не хранит")
    func nullStoreKeepsNothing() {
        let store = NullProgressStore()
        store.save(Self.saved)
        #expect(store.load() == nil)
    }

    // MARK: - Что годится для продолжения

    @Test("Сохранение в пределах набора уровней принимается как есть")
    func validSaveIsResumed() {
        #expect(GameProgressRules.resumable(Self.saved, totalLevels: 3) == Self.saved)
    }

    @Test("Без сохранения игра начинается сначала")
    func missingSaveStartsFromScratch() {
        #expect(GameProgressRules.resumable(nil, totalLevels: 3) == .initial)
    }

    /// Уровни убрали из сборки, а сохранение осталось: индекс вышел за границы
    /// и обращение к `Levels.all` уронило бы игру на запуске.
    @Test("Индекс уровня за пределами набора откатывает к началу")
    func levelIndexOutOfRangeStartsFromScratch() {
        let saved = GameProgress(currentLevelIndex: 7, carriedBonusPoints: 200)
        #expect(GameProgressRules.resumable(saved, totalLevels: 3) == .initial)
    }

    @Test("Отрицательный индекс уровня тоже откатывает к началу")
    func negativeLevelIndexStartsFromScratch() {
        let saved = GameProgress(currentLevelIndex: -1, carriedBonusPoints: 0)
        #expect(GameProgressRules.resumable(saved, totalLevels: 3) == .initial)
    }

    @Test("Отрицательный счёт откатывает к началу")
    func negativeBonusStartsFromScratch() {
        let saved = GameProgress(currentLevelIndex: 0, carriedBonusPoints: -10)
        #expect(GameProgressRules.resumable(saved, totalLevels: 3) == .initial)
    }

    /// Сохранение сделано на уровне, где флагов стало меньше: игра не падает,
    /// а откатывает игрока на старт уровня — это уже забота CheckpointRules.
    @Test("Неизвестная точка восстановления не мешает продолжить уровень")
    func unknownCheckpointStillResumes() {
        let saved = GameProgress(currentLevelIndex: 1,
                                 carriedBonusPoints: 50,
                                 activeCheckpointIndex: 9)

        let resumed = GameProgressRules.resumable(saved, totalLevels: 3)

        #expect(resumed == saved)
        #expect(CheckpointRules.respawnOrigin(checkpoints: [],
                                              levelStart: TileCoordinate(x: 2, y: 1),
                                              activated: resumed.activeCheckpointIndex)
                == TileCoordinate(x: 2, y: 1))
    }

    // MARK: - Снимок для записи

    /// Очки, набранные внутри уровня, живут в `PlayerState`; в сохранение они
    /// попадают только через снимок. Без него монеты, собранные до флага,
    /// пропали бы при перезапуске игры — а сами монеты со сцены уже ушли.
    @Test("Снимок берёт очки, набранные к этому моменту")
    func snapshotCarriesCurrentBonus() {
        let progress = GameProgress(currentLevelIndex: 1,
                                    carriedBonusPoints: 30,
                                    activeCheckpointIndex: 0,
                                    collectedPickupIndices: [2])
        let state = PlayerState(health: 60, bonusPoints: 95)

        let snapshot = GameProgressRules.snapshot(progress: progress, state: state)

        #expect(snapshot.carriedBonusPoints == 95)
        // Всё остальное — без изменений.
        #expect(snapshot.currentLevelIndex == 1)
        #expect(snapshot.activeCheckpointIndex == 0)
        #expect(snapshot.collectedPickupIndices == [2])
    }

    /// Здоровье в сохранение не идёт: после перезапуска игрок возрождается на
    /// флаге с полным запасом — ровно как после гибели.
    @Test("Продолжение с сохранения даёт стартовое здоровье")
    func resumedStateStartsWithFullHealth() {
        let snapshot = GameProgressRules.snapshot(
            progress: GameProgress(currentLevelIndex: 1, carriedBonusPoints: 0),
            state: PlayerState(health: 20, bonusPoints: 95)
        )

        let state = GameProgressRules.initialPlayerState(for: snapshot)

        #expect(state.health == HealthConfiguration.standard.initial)
        #expect(state.bonusPoints == 95)
    }
}
