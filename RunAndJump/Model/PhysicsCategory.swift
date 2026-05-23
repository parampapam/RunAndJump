//
//  PhysicsCategory.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 05.05.2026.
//

import Foundation

enum PhysicsCategory {
    static let none: UInt32      = 0
    static let player: UInt32    = 1 << 0  // 0001
    static let ground: UInt32    = 1 << 1  // 0010
    static let enemy: UInt32     = 1 << 2  // 0100
    static let pickup: UInt32    = 1 << 3  // 1000
    static let portal: UInt32    = 1 << 4  // 10000
    static let platform: UInt32  = 1 << 5  // 100000
    static let wall: UInt32      = 1 << 6  // 1000000
    static let ladder: UInt32    = 1 << 7  // 10000000
}
