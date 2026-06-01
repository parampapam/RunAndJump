//
//  FrameClock.swift
//  RunAndJump
//
//  Created by Roman Pospelov on [сегодня].
//

import Foundation

/// Переводит абсолютное время кадра в дельту `dt` между соседними кадрами.
///
/// Игровой цикл SpriteKit отдаёт абсолютную метку времени, а движению нужна
/// разница с прошлым кадром. Эта чистая мелочь раньше дублировалась в каждом
/// узле, который ведёт что-то по времени (`MovingPlatform`, `PatrollingMovement`).
///
/// Первый кадр только фиксирует точку отсчёта и возвращает `nil` —
/// корректный `dt` появляется со второго вызова.
struct FrameClock {

    private var lastUpdateTime: TimeInterval?

    /// Секунды, прошедшие с прошлого вызова, либо `nil` на самом первом кадре.
    mutating func tick(at time: TimeInterval) -> TimeInterval? {
        defer { lastUpdateTime = time }
        guard let last = lastUpdateTime else { return nil }
        return time - last
    }
}
