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
        /// Горизонтальный пробег: полуинтервал колонок `[start, end)`.
        struct Run: Hashable {
            let start: Int
            let end: Int
        }

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
            var runs: Set<Run> = []
            var x = 0
            while x < map.width {
                guard map.isSolid(x: x, y: y) else {
                    x += 1
                    continue
                }
                let start = x
                while x < map.width, map.isSolid(x: x, y: y) { x += 1 }
                runs.insert(Run(start: start, end: x))
            }

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
}
