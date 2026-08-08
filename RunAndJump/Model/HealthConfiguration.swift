//
//  HealthConfiguration.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 08.08.2026.
//

import Foundation

/// Настройки шкалы здоровья — единственное место, где живут числа баланса:
/// стартовый запас, потолок, цена удара врага и вес аптечки. Правила
/// (`GameRules`) и прогресс (`GameProgressRules`) берут значения отсюда,
/// поэтому подкрутить сложность = поменять `standard` (или подставить
/// свою конфигурацию в тестах), не трогая ни сцену, ни узлы.
struct HealthConfiguration: Equatable {

    /// Запас здоровья в начале уровня.
    var initial: Int
    /// Потолок: больше этого здоровье не растёт, сколько аптечек ни собери.
    /// Он же — «полная» шкала прогресс-бара в HUD.
    var maximum: Int
    /// Сколько снимает касание врага (и попадание снаряда).
    var enemyHitDamage: Int
    /// Сколько добавляет зелёная аптечка.
    var pickupHeal: Int

    /// Доля потолка, на которой и ниже шкала считается «на исходе» (`.warning`).
    var warningFraction: Double
    /// Доля потолка, на которой и ниже шкала считается критической (`.critical`).
    var criticalFraction: Double

    /// Пороги заданы так, чтобы стартовые 100 очков были зелёными: жёлтый —
    /// когда осталось около двух с половиной касаний врага (50), красный —
    /// когда одно (20).
    static let standard = HealthConfiguration(
        initial: 100,
        maximum: 200,
        enemyHitDamage: 20,
        pickupHeal: 10,
        warningFraction: 0.25,
        criticalFraction: 0.10
    )
}

/// Насколько всё плохо. Чистая величина: HUD переводит её в цвет заливки,
/// но саму границу «зелёный / жёлтый / красный» считает модель.
enum HealthLevel: Equatable {
    case healthy
    case warning
    case critical
}

enum HealthRules {

    /// Приводит здоровье в допустимый диапазон `0...maximum`.
    /// Ниже нуля здоровье не уходит (смерть определяет `GameRules.isDead`),
    /// выше потолка — тоже: лишние аптечки просто пропадают.
    static func clamp(_ health: Int, configuration: HealthConfiguration = .standard) -> Int {
        min(max(health, 0), configuration.maximum)
    }

    /// Заполненность шкалы, `0...1`. Полная шкала — это потолок, а не старт:
    /// поэтому в начале уровня бар заполнен наполовину и видно, что запас
    /// ещё есть куда наращивать.
    static func fillFraction(for health: Int, configuration: HealthConfiguration = .standard) -> Double {
        guard configuration.maximum > 0 else { return 0 }
        return Double(clamp(health, configuration: configuration)) / Double(configuration.maximum)
    }

    /// Уровень тревоги по текущему здоровью.
    static func level(for health: Int, configuration: HealthConfiguration = .standard) -> HealthLevel {
        let fraction = fillFraction(for: health, configuration: configuration)
        if fraction <= configuration.criticalFraction { return .critical }
        if fraction <= configuration.warningFraction { return .warning }
        return .healthy
    }
}
