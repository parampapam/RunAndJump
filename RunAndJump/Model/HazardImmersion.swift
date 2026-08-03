//
//  HazardImmersion.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 03.08.2026.
//

import CoreGraphics

/// Насколько глубоко игрок погружён в озеро — чистая геометрия по горизонтали.
///
/// Доля ширины игрока, оказавшаяся над зоной: целиком в озере — 1, на кромке —
/// сколько успел зайти, снаружи — 0. По этой доле сцена опускает спрайт.
///
/// Без неё погружение включалось бы по касанию тел, то есть рывком: выходящий
/// из воды игрок уже стоит на траве, а нарисован опущенным на полтайла — и
/// выглядит закопанным в землю, пока контакт не оборвётся.
enum HazardImmersion {

    /// - Parameters:
    ///   - player: габарит игрока по X, пункты.
    ///   - hazard: габарит зоны по X, пункты.
    /// - Returns: доля погружения в 0...1.
    static func depth(player: ClosedRange<CGFloat>, hazard: ClosedRange<CGFloat>) -> CGFloat {
        let overlap = min(player.upperBound, hazard.upperBound)
            - max(player.lowerBound, hazard.lowerBound)
        guard overlap > 0 else { return 0 }

        // Мерка — меньшая из ширин: озеро уже игрока топит его целиком, когда
        // он встал над ним, а не оставляет навсегда полупогружённым.
        let full = min(player.upperBound - player.lowerBound,
                       hazard.upperBound - hazard.lowerBound)
        guard full > 0 else { return 0 }

        return min(1, overlap / full)
    }
}
