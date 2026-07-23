//
//  CameraMath.swift
//  RunAndJump
//

import CoreGraphics

/// Чистая геометрия клэмпа камеры — не даёт видимой области выйти за пределы
/// уровня. Модуль не знает о `SKCameraNode`: только точки и размеры.
enum CameraMath {
    /// Позиция камеры, ограниченная так, чтобы видимая область (`viewportSize`,
    /// уже с учётом зума) не выходила за границы уровня (`levelSize`).
    ///
    /// Если уровень меньше видимой области хотя бы по одной оси, верхняя и
    /// нижняя граница клэмпа по этой оси инвертируются, и `max` побеждает —
    /// камера прижимается к нижнему/левому краю (позиции `halfViewport`), а не
    /// центрируется на уровне.
    static func clampedPosition(target: CGPoint, viewportSize: CGSize, levelSize: CGSize) -> CGPoint {
        let halfW = viewportSize.width / 2
        let halfH = viewportSize.height / 2
        let x = max(halfW, min(levelSize.width - halfW, target.x))
        let y = max(halfH, min(levelSize.height - halfH, target.y))
        return CGPoint(x: x, y: y)
    }
}
