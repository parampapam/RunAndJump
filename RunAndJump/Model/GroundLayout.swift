//
//  GroundLayout.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 03.08.2026.
//

import CoreGraphics

/// Раскладка земли по горизонтали: сплошная полоса, из которой вырезаны проёмы
/// под озёрами. Чистая геометрия в тайлах — сцена только строит по ней тела и
/// травяное покрытие.
///
/// Проём нужен, чтобы озеро было настоящей ямой: игрок шагает в него и
/// проваливается на опору ниже, а не идёт по воде поверх сплошного грунта.
enum GroundLayout {

    /// Куски земли, оставшиеся между проёмами.
    ///
    /// Проёмы можно передавать в любом порядке; пересекающиеся и соприкасающиеся
    /// схлопываются, вылезающие за пределы уровня обрезаются.
    ///
    /// - Parameters:
    ///   - width: ширина уровня в тайлах.
    ///   - gaps: проёмы — габариты озёр по X, в тайлах.
    static func segments(levelWidthInTiles width: CGFloat,
                         gaps: [ClosedRange<CGFloat>]) -> [ClosedRange<CGFloat>] {
        guard width > 0 else { return [] }

        var segments: [ClosedRange<CGFloat>] = []
        var start: CGFloat = 0

        for gap in gaps.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            let from = min(max(gap.lowerBound, 0), width)
            let to = min(max(gap.upperBound, 0), width)
            if from > start {
                segments.append(start...from)
            }
            start = max(start, to)
        }

        if start < width {
            segments.append(start...width)
        }
        return segments
    }
}
