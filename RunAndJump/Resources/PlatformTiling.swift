//
//  PlatformTiling.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 06.08.2026.
//

import CoreGraphics

/// Раскладка платформы по колонкам — слева направо: левый край, ноль и более
/// средних плиток, правый край. Чистая логика, без SpriteKit: узлы (`Platform`,
/// `MovingPlatform`) только строят по ней спрайты.
///
/// Возвращает **части**, а не имена текстур: раскладка одинакова во всех стилях,
/// а чем нарисован левый край — знание стиля (`TerrainNames`). Пока здесь стояли
/// имена из `TextureName`, чистая логика была намертво привязана к одному стилю.
///
/// Толщина платформы (0.25 тайла) — это высота её физического ребра, а не
/// картинки: у текстур своя нарисованная толщина, поэтому здесь участвует
/// только ширина. Ширина может быть дробной — тогда колонок берётся столько,
/// сколько ближе всего к целому числу тайлов, и они чуть тянутся по ширине:
/// обрезать колонку нельзя, у краёв скруглённые торцы.
enum PlatformTiling {

    /// Роль колонки в платформе. Имя текстуры по ней даёт каталог стиля.
    enum Part: Equatable, Sendable {
        case left
        case middle
        case right
    }

    /// Колонки платформы заданной ширины (в тайлах, > 0), слева направо.
    static func parts(forWidthInTiles width: CGFloat) -> [Part] {
        precondition(width > 0, "Ширина платформы должна быть положительной")

        switch columnCount(forWidthInTiles: width) {
        case 1:
            // Слишком узко для двух торцов — одна средняя плитка.
            return [.middle]
        case let count:
            return [.left] + Array(repeating: .middle, count: count - 2) + [.right]
        }
    }

    /// Сколько колонок укладывается в заданную ширину. Минимум — одна.
    static func columnCount(forWidthInTiles width: CGFloat) -> Int {
        max(1, Int(width.rounded()))
    }
}
