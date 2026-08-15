//
//  BackgroundTextures.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 15.08.2026.
//

import Foundation

/// Чем нарисован каждый сегмент фона. Как и `DecorationTiles`, живёт в слое
/// ресурсов: модель знает, **какой** сегмент стоит на месте, а из чего он
/// нарисован — знание об ассетах.
///
/// `nil` — сегмент ничего не рисует, и на его месте видна заливка.
enum BackgroundTextures {

    static func name(for fill: BackgroundFill) -> String {
        switch fill {
        case .daySky: return TextureName.Background.daySky
        }
    }

    static func name(for segment: HorizonSegment) -> String? {
        switch segment {
        case .hills: return TextureName.Background.hills
        case .mountains: return TextureName.Background.mountains
        case .fill: return nil
        }
    }

    static func name(for segment: SkySegment) -> String {
        switch segment {
        case .clouds: return TextureName.Background.clouds
        }
    }
}
