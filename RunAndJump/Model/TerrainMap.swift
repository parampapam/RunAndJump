//
//  TerrainMap.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 20.09.2026.
//

import CoreGraphics
import Foundation

/// Рельеф уровня — сетка клеток: в клетке либо сплошной грунт, либо пусто.
/// Чистые данные, без SpriteKit.
///
/// Карта — единственный источник правды про форму земли: из неё выводятся и
/// физические тела (`TerrainLayout`), и раскладка плиток. Автор не размечает,
/// где поверхность, а где стена: поверхность — это верхняя занятая клетка
/// колонки, и вычислить её дешевле, чем помнить.
///
/// Начало координат — **нижний-левый угол уровня**, как у всех описаний:
/// клетка (0, 0) лежит в левом нижнем углу, `y` растёт вверх.
struct TerrainMap: Equatable {

    /// Что лежит в клетке.
    ///
    /// Закрытый `enum`, а не `Bool`: видов грунта два, и различаются они
    /// **только физикой**. Рисуются одинаково — раскладка (`TerrainTiling`)
    /// разницы между ними не видит, иначе у проходимого холма пришлось бы
    /// заводить свой набор плиток.
    enum Cell: Equatable {
        case empty
        /// Сплошной грунт: в него упираются с любой стороны.
        case solid
        /// Проходимый грунт: сквозь него ходят, на него запрыгивают.
        ///
        /// Холм на заднем плане, мимо которого идут по земле и на который
        /// можно забраться. Держит только **сверху** и только открытой
        /// поверхностью — это обычная односторонняя опора, та же, что у
        /// площадок (`Platform`). Рисуется позади игрока
        /// (`ZPosition.terrainBack`): внутри такого холма игрок оказывается
        /// постоянно, и закрывать его собой холм не должен.
        case passable
    }

    let width: Int
    let height: Int

    /// Клетки построчно, **снизу вверх**: индекс `y * width + x`.
    private let cells: [Cell]

    init(width: Int, height: Int, cells: [Cell]) {
        precondition(width > 0 && height > 0, "Карта рельефа не может быть пустой")
        precondition(cells.count == width * height, "Размер карты не сходится с числом клеток")
        self.width = width
        self.height = height
        self.cells = cells
    }

    /// Что в клетке, **с учётом правила границ**: ниже нижнего края уровня
    /// земля считается сплошной, за остальными краями — пусто.
    ///
    /// Правило про низ нужно раскладке: без него массив, доходящий до нижнего
    /// края уровня, получил бы скруглённый низ на самом краю экрана — там, где
    /// земля по смыслу продолжается вниз.
    func cell(x: Int, y: Int) -> Cell {
        guard y >= 0 else { return .solid }
        guard x >= 0, x < width, y < height else { return .empty }
        return cells[y * width + x]
    }

    /// Только сплошной грунт — вопрос **физики**: из чего строятся тела.
    func isSolid(x: Int, y: Int) -> Bool {
        cell(x: x, y: y) == .solid
    }

    /// Занята ли клетка хоть чем-то.
    func isOccupied(x: Int, y: Int) -> Bool {
        cell(x: x, y: y) != .empty
    }

    /// Видит ли клетка вида `kind` соседа в `(x, y)` при выборе плитки.
    ///
    /// Правило **асимметрично**, и это не недосмотр, а сам смысл проходимого
    /// грунта: он лежит в другой плоскости, позади переднего плана.
    ///
    /// - **Сплошной грунт не видит проходимый.** Земля, по которой идут перед
    ///   холмом, обязана выглядеть поверхностью — с полосой покрытия, — иначе
    ///   игрок шагает по тому, что нарисовано как толща. Холм над ней ничего
    ///   не закрывает: он позади.
    /// - **Проходимый видит сплошной.** Холм стоит на земле, а не висит над
    ///   ней, поэтому его нижний ряд продолжается в неё, а не обрывается
    ///   скруглённым низом.
    func isNeighbour(x: Int, y: Int, of kind: Cell) -> Bool {
        switch kind {
        case .solid: return isSolid(x: x, y: y)
        case .passable, .empty: return isOccupied(x: x, y: y)
        }
    }

    /// Можно ли стоять в клетке `(x, y)`.
    ///
    /// Три условия, и каждое отвечает на свой промах автора:
    /// - своя клетка не сплошная — иначе объект замурован в грунте;
    /// - снизу сплошной грунт **или** открытый верх проходимого;
    /// - под клеткой есть ряд: нижний край уровня опорой не считается.
    ///
    /// «Открытый верх проходимого» — не придирка: одностороннее ребро есть
    /// только у верхней клетки проходимого участка, и стоящий **внутри** холма
    /// провалится сквозь него на землю.
    func supportsStanding(x: Int, y: Int) -> Bool {
        guard y >= 1 else { return false }

        let own = cell(x: x, y: y)
        guard own != .solid else { return false }

        switch cell(x: x, y: y - 1) {
        case .solid: return true
        case .passable: return own != .passable
        case .empty: return false
        }
    }

    /// Карта с вырезанными проёмами: клетки, которых касается любой из
    /// прямоугольников, становятся пустыми.
    ///
    /// Так озеро превращается в настоящую яму: грунт под ним вырезан, и
    /// шагнувший туда игрок проваливается на опору ниже (`HazardKind`).
    /// Прямоугольник, попавший на дробную границу, вырезает клетку целиком —
    /// озёра задаются целыми тайлами по сетке (см. `HazardDescriptor`).
    ///
    /// Это карта **физики**. Для выбора плиток нужна другая — `filling`.
    func carving(_ rects: [TileRect]) -> TerrainMap {
        replacing(rects, with: .empty)
    }

    /// Карта с закрашенными прямоугольниками: клетки, которых они касаются,
    /// становятся занятыми.
    ///
    /// Нужна ровно для одного: **жидкость — часть рельефа, когда выбирается
    /// плитка**. Иначе грунт на берегу видит рядом пустоту и берёт торцевую
    /// плитку, а у торцов края скруглены и прозрачны — между землёй и водой
    /// открывается щель. Клетка озера сама при этом не рисуется: она вырезана
    /// из карты физики, по которой и решается, где класть плитки.
    ///
    /// То же самое делают в редакторах уровней, добавляя воду в слой
    /// коллизий, чтобы правила авто-раскладки выбирали плитки правильно.
    func filling(_ rects: [TileRect]) -> TerrainMap {
        replacing(rects, with: .solid)
    }

    private func replacing(_ rects: [TileRect], with cell: Cell) -> TerrainMap {
        guard !rects.isEmpty else { return self }

        var changed = cells
        for rect in rects {
            let minX = max(0, Int(rect.origin.x.rounded(.down)))
            let maxX = min(width, Int((rect.origin.x + rect.size.width).rounded(.up)))
            let minY = max(0, Int(rect.origin.y.rounded(.down)))
            let maxY = min(height, Int((rect.origin.y + rect.size.height).rounded(.up)))

            guard minX < maxX, minY < maxY else { continue }
            for y in minY..<maxY {
                for x in minX..<maxX {
                    changed[y * width + x] = cell
                }
            }
        }
        return TerrainMap(width: width, height: height, cells: changed)
    }
}

// MARK: - Авторский вид

extension TerrainMap {

    /// Карта из картинки: `'#'` — грунт, `'.'` — пусто, строки идут **сверху
    /// вниз**, как на экране.
    ///
    /// ```
    /// TerrainMap("""
    /// ..............
    /// ...####.......
    /// ..#########...
    /// ##############
    /// """)
    /// ```
    ///
    /// `'+'` — проходимый грунт: сквозь него ходят, на него запрыгивают
    /// (`Cell.passable`).
    ///
    /// Разбор строгий: неровные строки и незнакомые символы роняют сборку на
    /// месте. Карты лежат в коде рядом с остальным описанием уровня, поэтому
    /// это опечатка автора, а не ситуация, в которой может оказаться игрок.
    init(_ picture: String) {
        var rows = picture
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        while let first = rows.first, first.isEmpty { rows.removeFirst() }
        while let last = rows.last, last.isEmpty { rows.removeLast() }

        guard let first = rows.first else {
            preconditionFailure("Карта рельефа пуста")
        }
        let width = first.count
        precondition(rows.allSatisfy { $0.count == width },
                     "Строки карты рельефа разной длины")

        // Строки перечислены сверху вниз, а клетки хранятся снизу вверх.
        let cells = rows.reversed().flatMap { row in
            row.map { character -> Cell in
                switch character {
                case "#": return .solid
                case "+": return .passable
                case ".": return .empty
                default: preconditionFailure("Неизвестный символ карты рельефа: \(character)")
                }
            }
        }
        self.init(width: width, height: rows.count, cells: cells)
    }

    /// Сплошной пол заданной толщины вдоль всего низа уровня — то, чем была
    /// земля до появления рельефа.
    static func floor(width: Int, height: Int, thicknessInTiles thickness: Int = 1) -> TerrainMap {
        precondition(thickness >= 0, "Толщина пола не может быть отрицательной")
        let solid = min(thickness, height)
        let cells = (0..<(width * height)).map { index in
            index < width * solid ? Cell.solid : .empty
        }
        return TerrainMap(width: width, height: height, cells: cells)
    }
}
