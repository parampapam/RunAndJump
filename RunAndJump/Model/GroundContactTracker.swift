//
//  GroundContactTracker.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 22.06.2026.
//

import Foundation

/// Учёт опор под игроком (земля + платформы). «Игрок на земле» = есть хотя бы
/// одна опора.
///
/// Зачем отдельный тип: контакты приходят по одному, а приземление — это
/// объединение всех текущих опор. Если считать «на земле» по одному контакту,
/// то подвижная платформа, опускаясь сквозь стоящего на земле игрока, даёт пару
/// «контакт начался → контакт закончился» и ложно снимает приземление — игрок
/// теряет возможность прыгать, хотя продолжает стоять на земле.
///
/// Чистая модель без SpriteKit: сцена кормит её идентификаторами тел-опор и
/// сообщает [[JumpController]] о приземлении/отрыве по возвращаемым переходам.
struct GroundContactTracker<Support: Hashable> {

    /// Опоры, которых игрок касается прямо сейчас.
    private(set) var supports: Set<Support> = []

    /// Стоит ли игрок хоть на одной опоре.
    var isGrounded: Bool { !supports.isEmpty }

    /// Регистрирует новую опору (контакт начался).
    mutating func add(_ support: Support) {
        supports.insert(support)
    }

    /// Убирает опору (контакт закончился). Возвращает `true` только когда это был
    /// фактический отрыв от земли — реально существовавшая опора исчезла и других
    /// не осталось. Повторные/чужие `remove` перехода не дают.
    @discardableResult
    mutating func remove(_ support: Support) -> Bool {
        guard supports.remove(support) != nil else { return false }
        return supports.isEmpty
    }
}
