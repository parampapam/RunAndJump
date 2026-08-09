//
//  GameProgress.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.05.2026.
//

import Foundation

/// Состояние прогресса игрока через все уровни.
/// Чистая модель — не зависит от SpriteKit.
///
/// `Codable` — потому что это ровно то, что сохраняется между запусками
/// приложения (см. `GameProgressStore`): iOS выгружает свёрнутую игру из
/// памяти, и без записи на диск игрок вернулся бы на первый уровень.
/// Совместимость версий отдельно не поддерживается: изменившаяся форма даст
/// ошибку разбора, а она трактуется как «сохранения нет» — начинаем сначала.
struct GameProgress: Equatable, Codable {
    var currentLevelIndex: Int
    var carriedBonusPoints: Int
    /// Индекс пройденной точки восстановления в `LevelConfiguration.checkpoints`
    /// текущего уровня; `nil` — игрок ещё не миновал ни одного флага и
    /// возрождается на старте уровня.
    ///
    /// Живёт здесь, потому что гибель пересоздаёт сцену, а `GameProgress` —
    /// единственное, что переживает пересоздание. При переходе на следующий
    /// уровень сбрасывается: индексы точек у каждого уровня свои.
    var activeCheckpointIndex: Int? = nil
    /// Индексы уже поднятых наград в `LevelConfiguration.pickups` текущего
    /// уровня — тех, что не возвращаются после гибели (см.
    /// `PickupKind.staysCollectedAfterDeath`). Аптечки сюда не попадают.
    ///
    /// Живёт здесь по той же причине, что и точка восстановления: сцена
    /// пересобирает уровень с нуля, и без этого списка монеты, за которые очки
    /// уже начислены, можно было бы собрать повторно.
    var collectedPickupIndices: Set<Int> = []
    /// Индексы врагов в `LevelConfiguration.enemies`, победа над которыми уже
    /// засчитана окончательно, — побеждённых **до** последнего поднятого флага.
    /// Они на уровень не возвращаются.
    ///
    /// В отличие от наград, победа над врагом засчитывается не сразу, а флагом:
    /// побеждённые после него возвращаются вместе с очками за них (см.
    /// `EnemyRespawnRules`). Поэтому «побеждён с последнего флага» — состояние
    /// текущей жизни, оно живёт в сцене и вместе с ней умирает; сюда попадает
    /// только то, что флаг успел засчитать.
    var defeatedEnemyIndices: Set<Int> = []

    static let initial = GameProgress(currentLevelIndex: 0, carriedBonusPoints: 0)
}

enum GameProgressRules {

    /// После успешного прохождения уровня: переносим бонусы, инкрементируем
    /// индекс. Точка восстановления сбрасывается — на новом уровне свои флаги,
    /// и игрок начинает его со старта.
    static func levelCompleted(progress: GameProgress, finalState: PlayerState) -> GameProgress {
        GameProgress(
            currentLevelIndex: progress.currentLevelIndex + 1,
            carriedBonusPoints: finalState.bonusPoints,
            activeCheckpointIndex: nil,
            collectedPickupIndices: [],
            defeatedEnemyIndices: []
        )
    }

    /// Игрок поднял флаг: точка восстановления смещается сюда, а победы над
    /// врагами с прошлого возрождения засчитываются окончательно — до этого
    /// флага уровень уже не откатится, значит и враги не вернутся.
    static func checkpointReached(progress: GameProgress,
                                  index: Int,
                                  defeatedSinceCheckpoint: Set<Int>) -> GameProgress {
        var updated = progress
        updated.activeCheckpointIndex = index
        updated.defeatedEnemyIndices.formUnion(defeatedSinceCheckpoint)
        return updated
    }

    /// После гибели: уровень начинается заново от точки восстановления, но
    /// набранные очки остаются — они переходят в перенос, как при завершении
    /// уровня. Здоровье при этом восстанавливается до стартового
    /// (`initialPlayerState`), а список поднятых монет не трогаем: очки за них
    /// уже сохранены, второй раз их подобрать нельзя.
    ///
    /// Исключение — враги, которые вернутся на уровень (`restoredEnemies`,
    /// побеждённые после последнего флага): за них очки снимаются, иначе счёт
    /// разошёлся бы с уровнем. См. `EnemyRespawnRules`.
    static func playerDied(progress: GameProgress,
                           finalState: PlayerState,
                           restoredEnemies: Set<Int> = [],
                           enemies: [EnemyDescriptor] = []) -> GameProgress {
        var updated = progress
        let refund = EnemyRespawnRules.refund(for: restoredEnemies, in: enemies)
        // Снять можно только то, что было начислено: в минус счёт не уходит.
        updated.carriedBonusPoints = max(0, finalState.bonusPoints - refund)
        return updated
    }

    /// Снимок прогресса для сохранения между запусками: то же состояние, но с
    /// очками, набранными игроком **прямо сейчас**.
    ///
    /// Нужен потому, что `carriedBonusPoints` — это очки на *входе* в уровень;
    /// набранное внутри живёт в `PlayerState` и попадает в прогресс только при
    /// гибели или на выходе с уровня. Сохранение же случается ещё и на флаге,
    /// посреди уровня, и без этой склейки монеты, собранные до флага,
    /// пропадали бы при перезапуске игры — хотя сами монеты со сцены уже ушли
    /// (`collectedPickupIndices`).
    static func snapshot(progress: GameProgress, state: PlayerState) -> GameProgress {
        var updated = progress
        updated.carriedBonusPoints = state.bonusPoints
        return updated
    }

    /// Прогресс, с которого начинается запуск: сохранённый — если он всё ещё
    /// осмыслен для текущего набора уровней, иначе начальный.
    ///
    /// Проверяем только индекс уровня: по нему выбирается `LevelConfiguration`,
    /// и выход за границы уронил бы игру. Индексы внутри уровня (точка
    /// восстановления, награды, враги) переживают любое изменение описания
    /// уровня сами: неизвестный флаг откатывается на старт
    /// (`CheckpointRules.respawnOrigin`), а лишние индексы наград и врагов
    /// просто никого не отфильтровывают.
    static func resumable(_ saved: GameProgress?, totalLevels: Int) -> GameProgress {
        guard let saved,
              (0..<totalLevels).contains(saved.currentLevelIndex),
              saved.carriedBonusPoints >= 0
        else { return .initial }
        return saved
    }

    /// Признак, что игрок прошёл все уровни.
    static func isGameCompleted(progress: GameProgress, totalLevels: Int) -> Bool {
        progress.currentLevelIndex >= totalLevels
    }

    /// Создаёт начальное состояние игрока для нового уровня:
    /// здоровье сбрасывается до стартового запаса, бонусы переносятся.
    static func initialPlayerState(
        for progress: GameProgress,
        health configuration: HealthConfiguration = .standard
    ) -> PlayerState {
        PlayerState(health: configuration.initial, bonusPoints: progress.carriedBonusPoints)
    }
}
