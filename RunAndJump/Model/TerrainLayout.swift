//
//  TerrainLayout.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 20.09.2026.
//

import CoreGraphics

/// Перевод карты рельефа в физические тела: занятые клетки склеиваются в
/// минимальное число прямоугольников. Чистая геометрия в тайлах — сцена только
/// строит по ней узлы с телами.
///
/// **Склейка — требование физики, а не оптимизация.** Сотня отдельных
/// `SKPhysicsBody` в ряд даёт швы, на которых бегущий игрок спотыкается. Раньше
/// этого не было видно только потому, что куски земли разделялись проёмами под
/// озёрами и не соприкасались; с рельефом соприкасаются почти все.
enum TerrainLayout {

    /// Тела рельефа: прямоугольники в тайлах, нижний-левый угол + размер.
    ///
    /// Сначала в каждом ряду берутся максимальные горизонтальные пробеги, потом
    /// соседние ряды с совпадающими границами пробега склеиваются по вертикали.
    /// Отсюда нужная гарантия: **любая поверхность, по которой можно бежать, —
    /// верх одного пробега, то есть одно тело**. Оставшиеся швы внутренние,
    /// между сплошными телами, и игроку недоступны.
    ///
    /// Порядок в результате — снизу вверх, слева направо.
    static func bodies(of map: TerrainMap) -> [TileRect] {
        var result: [TileRect] = []
        /// Пробеги, начатые ниже и ещё не закрытые: пробег → ряд, где он начался.
        var open: [Run: Int] = [:]

        func close(_ run: Run, from startY: Int, to endY: Int) {
            result.append(
                TileRect(origin: TileCoordinate(x: CGFloat(run.start), y: CGFloat(startY)),
                         size: TileSize(width: CGFloat(run.end - run.start),
                                        height: CGFloat(endY - startY)))
            )
        }

        for y in 0..<map.height {
            let runs = Set(self.runs(inRow: y, of: map, where: { $0.isSolid(x: $1, y: $2) }))

            // Пробег, не повторившийся в этом ряду, закончился на предыдущем.
            for (run, startY) in open where !runs.contains(run) {
                close(run, from: startY, to: y)
                open[run] = nil
            }
            for run in runs where open[run] == nil {
                open[run] = y
            }
        }

        for (run, startY) in open {
            close(run, from: startY, to: map.height)
        }

        return result.sorted {
            $0.origin.y == $1.origin.y ? $0.origin.x < $1.origin.x : $0.origin.y < $1.origin.y
        }
    }

    /// Односторонние опоры проходимого грунта: открытые сверху участки его
    /// поверхности, слева направо и снизу вверх.
    ///
    /// Одна опора на участок, а не на клетку, — по той же причине, что и
    /// склейка тел: на швах между соседними рёбрами игрок спотыкается.
    ///
    /// Ребро появляется только там, где над клеткой **пусто**. Проходимая
    /// клетка под сплошной опоры не даёт: сверху её всё равно накрывает тело
    /// сплошного грунта, а второе ребро внутри массива ловило бы игрока
    /// изнутри.
    static func surfaces(of map: TerrainMap) -> [TerrainSurface] {
        var result: [TerrainSurface] = []

        for y in 0..<map.height {
            let exposed = runs(inRow: y, of: map) { map, x, y in
                map.cell(x: x, y: y) == .passable && !map.isOccupied(x: x, y: y + 1)
            }
            for run in exposed {
                result.append(
                    TerrainSurface(y: CGFloat(y + 1),
                                   xSpan: CGFloat(run.start)...CGFloat(run.end))
                )
            }
        }
        return result
    }

    /// Горизонтальный пробег клеток, отвечающих условию: полуинтервал
    /// колонок `[start, end)`.
    private struct Run: Hashable {
        let start: Int
        let end: Int
    }

    private static func runs(inRow y: Int,
                             of map: TerrainMap,
                             where matches: (TerrainMap, Int, Int) -> Bool) -> [Run] {
        var runs: [Run] = []
        var x = 0
        while x < map.width {
            guard matches(map, x, y) else {
                x += 1
                continue
            }
            let start = x
            while x < map.width, matches(map, x, y) { x += 1 }
            runs.append(Run(start: start, end: x))
        }
        return runs
    }
}

/// Одностороннее ребро: верх участка проходимого грунта. На него встают
/// сверху, сквозь него проходят снизу и сбоку.
struct TerrainSurface: Equatable {
    /// Высота поверхности в тайлах — линия, по которой идёт ребро.
    let y: CGFloat
    /// Протяжённость по X, тайлы.
    let xSpan: ClosedRange<CGFloat>
}
