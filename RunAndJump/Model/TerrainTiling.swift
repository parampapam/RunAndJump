//
//  TerrainTiling.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 20.09.2026.
//

import CoreGraphics

/// Какой плиткой нарисована клетка рельефа. Чистая логика без SpriteKit: имя
/// текстуры по части даёт каталог стиля (`TerrainNames`), спрайт собирает
/// `LevelBuilder`.
///
/// Роль выводится из занятости соседей, а не задаётся автором. Иначе в
/// описаниях уровней завелись бы имена плиток, и правка формы холма стала бы
/// правкой картинок.
enum TerrainTiling {

    /// Роль клетки в массиве грунта. Девятислайс плюс две плитки уступа.
    enum Part: Equatable, Sendable, CaseIterable {
        case topLeft, topMiddle, topRight
        case left, right
        case inside
        /// Внутренняя клетка **перед** началом поверхности справа от неё:
        /// полоса покрытия заворачивается в её правый верхний угол.
        case insideBeforeTop
        /// Зеркальная: внутренняя клетка сразу **после** конца поверхности
        /// слева от неё.
        case insideAfterTop
        case bottomLeft, bottomMiddle, bottomRight
    }

    /// Роль клетки. Клетка предполагается занятой: у пустой роли нет.
    ///
    /// Вид грунта роли не меняет: проходимый холм выкладывается тем же
    /// девятислайсом, что и сплошной, — они различаются физикой, а не
    /// картинкой.
    ///
    /// Порядок ветвления — часть правила, а не деталь реализации: у угловой
    /// клетки подходит сразу несколько условий. Верх важнее низа, низ важнее
    /// боков, бока важнее уступа.
    ///
    /// **Верх важнее низа** диктует не рельеф, а пол: он высотой ровно в тайл,
    /// и у него одновременно открыты верх и низ. Низ пола уходит за нижний край
    /// уровня и никому не виден, а верх — то, по чему ходят.
    static func part(x: Int, y: Int, in map: TerrainMap) -> Part {
        let up = map.isOccupied(x: x, y: y + 1)
        let down = map.isOccupied(x: x, y: y - 1)
        let left = map.isOccupied(x: x - 1, y: y)
        let right = map.isOccupied(x: x + 1, y: y)

        if !up {
            if !left, right { return .topLeft }
            if left, !right { return .topRight }
            // Оба бока открыты — одиночная клетка или полка в один тайл. Два
            // ровных торца честнее, чем скруглённая шапка с одной стороны и
            // обрубок с другой.
            return .topMiddle
        }

        if !down {
            if !left, right { return .bottomLeft }
            if left, !right { return .bottomRight }
            return .bottomMiddle
        }

        // Открытый бок. Колонка шириной в один тайл (открыты оба) набором не
        // рисуется — нужна плитка «левый и правый край сразу», а её нет;
        // выбираем левый край и ловим случай валидацией.
        if !left { return .left }
        if !right { return .right }

        // Толща. Осталось отличить глухую от уступа: если сосед по горизонтали
        // ничем не накрыт, значит рядом кончается поверхность, и полоса
        // покрытия должна завернуться в угол этой клетки.
        if !map.isOccupied(x: x + 1, y: y + 1) { return .insideBeforeTop }
        if !map.isOccupied(x: x - 1, y: y + 1) { return .insideAfterTop }
        return .inside
    }
}
