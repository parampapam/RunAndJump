//
//  GameInputDelegate.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 01.06.2026.
//

/// Семантические команды ввода, не зависящие от источника.
///
/// Один и тот же набор событий порождают и экранные кнопки (`InputController`),
/// и физический геймпад (`GamepadInput`). Сцена реагирует на смысл команды,
/// ничего не зная о том, откуда она пришла — это позволяет добавлять новые
/// источники ввода, не трогая игровую логику.
protocol GameInputDelegate: AnyObject {
    func inputDidPressLeft()
    func inputDidPressRight()
    func inputDidReleaseHorizontal()

    func inputDidPressUp()
    func inputDidPressDown()
    func inputDidReleaseVertical()

    func inputDidPressJump()
}
