//
//  OscillatingMotion.swift
//  RunAndJump
//
//  Created by Roman Pospelov on [сегодня].
//

import Foundation
import CoreGraphics

/// Остановка на маршруте: где стоять и сколько.
///
/// Место задаётся **долей пути**, а не тайлами: маршрут — отрезок, и его
/// естественная параметризация — прогресс от 0 (`startPosition`) до 1
/// (`endPosition`). Середина — 0.5 независимо от того, куда и как далеко идёт
/// платформа, а координату в тайлах пришлось бы проецировать на отрезок и
/// править после каждого сдвига концов.
///
/// Концы маршрута — **не особый случай**: это остановки с прогрессом 0 и 1.
/// Поэтому «в конце паузы нет» выражается отсутствием остановки в списке, а не
/// нулём в отдельном поле.
struct MotionStop: Equatable {

    /// 0 = `startPosition`, 1 = `endPosition`. Клампится в [0, 1].
    let progress: CGFloat
    /// Сколько секунд стоять. Неположительная остановка бессмысленна и
    /// отбрасывается движением: она не задержала бы, но сбила бы прогресс на
    /// свою отметку, то есть незаметно затормозила бы платформу.
    let duration: TimeInterval

    init(progress: CGFloat, duration: TimeInterval) {
        self.progress = min(max(progress, 0), 1)
        self.duration = duration
    }

    /// Остановка в произвольной точке маршрута.
    static func at(_ progress: CGFloat, _ duration: TimeInterval) -> MotionStop {
        MotionStop(progress: progress, duration: duration)
    }

    /// Остановка в начальной точке.
    static func start(_ duration: TimeInterval) -> MotionStop {
        MotionStop(progress: 0, duration: duration)
    }

    /// Остановка в конечной точке.
    static func end(_ duration: TimeInterval) -> MotionStop {
        MotionStop(progress: 1, duration: duration)
    }

    /// Одинаковая пауза в обоих концах — самый частый случай.
    static func atEnds(_ duration: TimeInterval) -> [MotionStop] {
        [.start(duration), .end(duration)]
    }
}

/// Движение между двумя точками туда-обратно с паузами на маршруте.
/// Чистая геометрия и тайминг — никакого SpriteKit. Единая реализация хода
/// «туда-обратно»: её использует и узел `MovingPlatform`, и патрулирующий враг
/// (`PatrollingMovement`) как частный случай — горизонтальный путь без остановок.
/// Вызывающая сторона переводит абсолютное время кадра в `dt` и применяет
/// полученную позицию.
///
/// Остановки (`MotionStop`) срабатывают в обе стороны: платформа встаёт на
/// каждой, куда бы ни шла. Разворот на концах отрезка — свойство маршрута, а не
/// остановки: без остановки в конце платформа разворачивается там без простоя.
struct OscillatingMotion: Equatable {

    // MARK: Конфигурация

    let startPosition: CGPoint
    let endPosition: CGPoint
    /// Скорость движения в точках в секунду.
    let speed: CGFloat
    /// Остановки на маршруте, включая концы. Пустой список = ход без пауз.
    let stops: [MotionStop]

    /// Полная длина пути между концами — определяет, как быстро растёт прогресс.
    private let totalDistance: CGFloat

    // MARK: Состояние

    /// 0 = startPosition, 1 = endPosition.
    private var progress: CGFloat = 0
    /// 1 = к endPosition, -1 = к startPosition.
    private var direction: CGFloat = 1
    /// Сколько ещё секунд стоять на остановке.
    private var pauseTimeRemaining: TimeInterval = 0

    /// - Parameters:
    ///   - stops: остановки на маршруте. Порядок не важен — движение само
    ///     выбирает ближайшую по ходу. Остановка ровно там, где платформа
    ///     стоит **сейчас**, не срабатывает: иначе платформа, отстоявшая свою
    ///     паузу, встала бы на той же отметке навсегда. Поэтому и старт с
    ///     `initialProgress` на остановке начинается сразу с движения.
    ///   - initialProgress: где начать на отрезке (0 = start, 1 = end),
    ///     клампится в [0, 1]. По умолчанию 0. Полезно для патрулирующего врага,
    ///     которого ставят в середине отрезка, а не на его краю.
    init(
        startPosition: CGPoint,
        endPosition: CGPoint,
        speed: CGFloat,
        stops: [MotionStop] = [],
        initialProgress: CGFloat = 0
    ) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.speed = speed
        self.stops = stops.filter { $0.duration > 0 }

        let dx = endPosition.x - startPosition.x
        let dy = endPosition.y - startPosition.y
        self.totalDistance = (dx * dx + dy * dy).squareRoot()
        self.progress = min(max(initialProgress, 0), 1)
    }

    /// Текущая позиция платформы — линейная интерполяция концов по прогрессу.
    var position: CGPoint {
        CGPoint(
            x: startPosition.x + (endPosition.x - startPosition.x) * progress,
            y: startPosition.y + (endPosition.y - startPosition.y) * progress
        )
    }

    /// Продвигает движение на `dt` секунд и возвращает новую позицию.
    /// На остановках выдерживает паузу, на концах отрезка разворачивается.
    ///
    /// Кадр тратится **целиком**: доехав до остановки, платформа тут же начинает
    /// на ней стоять, а досидев паузу — тут же трогается, всё в пределах одного
    /// вызова. Иначе каждое событие на маршруте съедало бы остаток кадра, и
    /// платформа отставала бы от расписания на кадр за остановку — при нескольких
    /// остановках это уже заметно.
    mutating func advance(by dt: TimeInterval) -> CGPoint {
        // Стоячая конфигурация: без этой проверки цикл ниже не сдвинул бы
        // прогресс, не потратил бы бюджет времени и не закончился бы.
        guard totalDistance > 0, speed > 0 else { return position }

        // Цикл конечен: каждый проход либо тратит время паузы, либо проезжает
        // до остановки/края — а их на отрезке конечное число, и путь между ними
        // тоже стоит времени.
        var timeLeft = dt
        while timeLeft > Self.spentFrameThreshold {
            if pauseTimeRemaining > 0 {
                let spent = min(pauseTimeRemaining, timeLeft)
                pauseTimeRemaining -= spent
                timeLeft -= spent
                continue
            }

            let target = progress + CGFloat(timeLeft) * speed / totalDistance * direction

            // Остановка на пути важнее конца отрезка: если кадр перекрыл разом и
            // остановку, и край, встаём на первую по ходу. Прогресс при этом
            // снимается ровно на её отметку — иначе платформа замирала бы каждый
            // раз в новом месте, с точностью до частоты кадров.
            if let stop = firstStop(from: progress, to: target) {
                timeLeft -= duration(from: progress, to: stop.progress)
                progress = stop.progress
                pauseTimeRemaining = stop.duration
                reverseIfAtEnd()
                continue
            }

            // Край отрезка: доезжаем до него, разворачиваемся и продолжаем тем
            // же кадром — разворот времени не стоит.
            if target > 1 {
                timeLeft -= duration(from: progress, to: 1)
                progress = 1
                direction = -1
                continue
            }
            if target < 0 {
                timeLeft -= duration(from: progress, to: 0)
                progress = 0
                direction = 1
                continue
            }

            progress = target
            reverseIfAtEnd()   // кадр закончился ровно на краю
            timeLeft = 0
        }

        return position
    }

    // MARK: Приватное

    /// Остаток кадра, ниже которого считаем кадр потраченным. Вычитания
    /// `double` не сходятся в ноль ровно (0.5 − 0.4 оставляет 1e-17 с), и без
    /// порога платформа доезжала бы этот мусор — сдвиг на доли нанометра, зато
    /// лишний проход цикла на каждом кадре.
    private static let spentFrameThreshold: TimeInterval = 1e-9

    /// Сколько секунд занимает проезд между двумя отметками прогресса.
    private func duration(from: CGFloat, to: CGFloat) -> TimeInterval {
        TimeInterval(abs(to - from) * totalDistance / speed)
    }

    /// Ближайшая по ходу остановка, которую пересекает отрезок прогресса
    /// (`from`, `to`]. Открытая граница со стороны `from` обязательна: платформа,
    /// только что отстоявшая паузу, стоит ровно на остановке, и включи мы её —
    /// она бы вставала на ту же паузу каждый кадр и никогда не тронулась.
    private func firstStop(from: CGFloat, to: CGFloat) -> MotionStop? {
        if to > from {
            let limit = min(to, 1)
            return stops
                .filter { $0.progress > from && $0.progress <= limit }
                .min { $0.progress < $1.progress }
        }
        if to < from {
            let limit = max(to, 0)
            return stops
                .filter { $0.progress < from && $0.progress >= limit }
                .max { $0.progress < $1.progress }
        }
        return nil
    }

    /// Разворот на концах отрезка — независимо от того, стоит там остановка или
    /// нет: дальше пути просто не существует.
    private mutating func reverseIfAtEnd() {
        if progress >= 1 {
            direction = -1
        } else if progress <= 0 {
            direction = 1
        }
    }
}
