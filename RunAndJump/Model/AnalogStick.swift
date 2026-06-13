//
//  AnalogStick.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 13.06.2026.
//

import CoreGraphics

/// Чистая геометрия аналогового стика — общая для экранного джойстика и
/// физического геймпада.
///
/// Преобразует «сырое» отклонение (смещение пальца от центра стика или
/// положение оси контроллера) в нормализованный вектор направления. Модуль
/// результата лежит в [0, 1] и задаёт *долю* максимальной скорости — именно
/// он позволяет персонажу идти медленнее при слабом отклонении и быстрее при
/// сильном.
///
/// Тип не знает ни о SpriteKit, ни о `UITouch`, ни о `GameController` —
/// только математика, поэтому полностью покрывается модульными тестами.
struct AnalogStick {

    /// Максимальный ход стика от центра. Для экранного джойстика — в точках;
    /// для геймпада, чьи оси уже нормированы, — единица.
    let radius: CGFloat

    /// Мёртвая зона как доля радиуса в [0, 1). Отклонения слабее неё считаем
    /// нейтралью — это отсекает дрейф стика и случайные микродвижения пальца.
    let deadZone: CGFloat

    init(radius: CGFloat, deadZone: CGFloat = 0.15) {
        self.radius = radius
        self.deadZone = max(0, min(deadZone, 0.99))
    }

    /// Положение «шляпки» относительно центра при заданном смещении пальца,
    /// ограниченное радиусом. Нужно сцене, чтобы нарисовать стик под пальцем,
    /// не позволяя ему выйти за пределы базы.
    func knobOffset(for offset: CGVector) -> CGVector {
        let distance = hypot(offset.dx, offset.dy)
        guard distance > radius else { return offset }
        let scale = radius / distance
        return CGVector(dx: offset.dx * scale, dy: offset.dy * scale)
    }

    /// Нормализованный вектор направления; компоненты в [-1, 1], модуль в [0, 1].
    ///
    /// - В пределах мёртвой зоны возвращает `.zero`.
    /// - Сразу за мёртвой зоной магнитуда стартует с 0 и плавно растёт до 1 на
    ///   краю — без скачка на границе зоны.
    /// - По диагонали модуль не превышает 1 (без «бега быстрее по диагонали»).
    func direction(for offset: CGVector) -> CGVector {
        let distance = hypot(offset.dx, offset.dy)
        guard distance > 0 else { return .zero }

        let normalizedMagnitude = min(distance, radius) / radius   // 0...1
        guard normalizedMagnitude > deadZone else { return .zero }

        // Перемасштабируем диапазон (deadZone...1] в (0...1], чтобы движение
        // начиналось мягко и доходило до полной скорости на краю.
        let magnitude = (normalizedMagnitude - deadZone) / (1 - deadZone)
        let unitX = offset.dx / distance
        let unitY = offset.dy / distance
        return CGVector(dx: unitX * magnitude, dy: unitY * magnitude)
    }
}
