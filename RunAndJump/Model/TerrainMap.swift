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
    /// Закрытый `enum`, а не `Bool`, ради односторонней опоры («запрыгнуть
    /// снизу сквозь»): когда она понадобится, это новый случай, а не новое
    /// поле рядом с существующим.
    enum Cell: Equatable {
        case empty
        case solid
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

    func isSolid(x: Int, y: Int) -> Bool {
        cell(x: x, y: y) == .solid
    }

    /// Карта с вырезанными проёмами: клетки, которых касается любой из
    /// прямоугольников, становятся пустыми.
    ///
    /// Так озеро превращается в настоящую яму: грунт под ним вырезан, и
    /// шагнувший туда игрок проваливается на опору ниже (`HazardKind`).
    /// Прямоугольник, попавший на дробную границу, вырезает клетку целиком —
    /// озёра задаются целыми тайлами по сетке (см. `HazardDescriptor`).
    func carving(_ rects: [TileRect]) -> TerrainMap {
        guard !rects.isEmpty else { return self }

        var carved = cells
        for rect in rects {
            let minX = max(0, Int(rect.origin.x.rounded(.down)))
            let maxX = min(width, Int((rect.origin.x + rect.size.width).rounded(.up)))
            let minY = max(0, Int(rect.origin.y.rounded(.down)))
            let maxY = min(height, Int((rect.origin.y + rect.size.height).rounded(.up)))

            guard minX < maxX, minY < maxY else { continue }
            for y in minY..<maxY {
                for x in minX..<maxX {
                    carved[y * width + x] = .empty
                }
            }
        }
        return TerrainMap(width: width, height: height, cells: carved)
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
