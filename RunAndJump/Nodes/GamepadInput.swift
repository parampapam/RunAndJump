//
//  GamepadInput.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 01.06.2026.
//

import CoreGraphics
import GameController

/// Источник ввода с физического геймпада (DualSense, DualShock 4,
/// Xbox Wireless, MFi-контроллеры — всё, что отдаёт `extendedGamepad`).
///
/// Транслирует «сырой» ввод (оси D-pad / стика, нажатие кнопки) в те же
/// семантические команды `GameInputDelegate`, что и экранные кнопки. Сцене
/// не нужно знать, что вообще существует геймпад — она получает привычные
/// «влево/вправо/вверх/вниз/прыжок».
///
/// Маппинг:
/// - D-pad и левый стик по X → влево / вправо (с порогом, чтобы стик не
///   срабатывал от лёгкого отклонения);
/// - D-pad и левый стик по Y → вверх / вниз (лестница);
/// - кнопка ✕ (cross на DualSense, A на Xbox) → прыжок.
@MainActor
final class GamepadInput {

    weak var delegate: GameInputDelegate?

    /// Вызывается при изменении состояния подключения: `true` — есть хотя бы
    /// один пригодный геймпад. Сцена прячет/показывает экранные кнопки.
    var onConnectionChange: ((Bool) -> Void)?

    /// Минимальное отклонение оси, ниже которого ввод считаем нейтральным.
    /// Отсекает дрейф стика и не даёт ему «дрожать» на границе.
    private let axisThreshold: CGFloat = 0.5

    private enum Horizontal { case left, right, none }
    private enum Vertical { case up, down, none }

    // Текущее дискретное состояние осей — события шлём только при переходах,
    // а не на каждый кадр, пока ось удерживается.
    private var horizontal: Horizontal = .none
    private var vertical: Vertical = .none

    private var observers: [NSObjectProtocol] = []

    /// Есть ли подключённый геймпад с расширенным профилем.
    var isConnected: Bool {
        GCController.controllers().contains { $0.extendedGamepad != nil }
    }

    // MARK: - Наблюдение

    func startObserving() {
        let center = NotificationCenter.default

        observers.append(center.addObserver(
            forName: .GCControllerDidConnect, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                // Перенастраиваем все подключённые контроллеры (configure
                // идемпотентен). Так не приходится тащить non-Sendable
                // объект уведомления через границу актора.
                for controller in GCController.controllers() {
                    self.configure(controller)
                }
                self.notifyConnection()
            }
        })

        observers.append(center.addObserver(
            forName: .GCControllerDidDisconnect, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                // Контроллер отвалился — сбрасываем удержание, чтобы игрок не
                // «застрял» в движении после потери связи.
                self?.resetAxes()
                self?.notifyConnection()
            }
        })

        // Подхватываем уже подключённые контроллеры (были до старта сцены).
        for controller in GCController.controllers() {
            configure(controller)
        }
        notifyConnection()
    }

    func stopObserving() {
        let center = NotificationCenter.default
        observers.forEach(center.removeObserver)
        observers.removeAll()
    }

    // MARK: - Конфигурация контроллера

    private func configure(_ controller: GCController) {
        guard let pad = controller.extendedGamepad else { return }

        // Коллбэки приходят на главную очередь — безопасно трогаем сцену.
        controller.handlerQueue = .main

        let axisHandler: GCControllerDirectionPadValueChangedHandler = { [weak self] _, _, _ in
            MainActor.assumeIsolated { self?.recomputeAxes(pad) }
        }
        pad.dpad.valueChangedHandler = axisHandler
        pad.leftThumbstick.valueChangedHandler = axisHandler

        // ✕ / A — прыжок. Реагируем только на нажатие (переход в pressed).
        pad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            MainActor.assumeIsolated {
                if pressed { self?.delegate?.inputDidPressJump() }
            }
        }
    }

    // MARK: - Трансляция осей

    private func recomputeAxes(_ pad: GCExtendedGamepad) {
        // Берём ту ось, что отклонена сильнее: D-pad или стик.
        let x = dominant(CGFloat(pad.dpad.xAxis.value), CGFloat(pad.leftThumbstick.xAxis.value))
        let y = dominant(CGFloat(pad.dpad.yAxis.value), CGFloat(pad.leftThumbstick.yAxis.value))

        let newHorizontal: Horizontal = x < -axisThreshold ? .left
            : (x > axisThreshold ? .right : .none)
        if newHorizontal != horizontal {
            horizontal = newHorizontal
            switch newHorizontal {
            case .left:  delegate?.inputDidPressLeft()
            case .right: delegate?.inputDidPressRight()
            case .none:  delegate?.inputDidReleaseHorizontal()
            }
        }

        // В GameController ось Y направлена вверх (вверх = положительная).
        let newVertical: Vertical = y > axisThreshold ? .up
            : (y < -axisThreshold ? .down : .none)
        if newVertical != vertical {
            vertical = newVertical
            switch newVertical {
            case .up:   delegate?.inputDidPressUp()
            case .down: delegate?.inputDidPressDown()
            case .none: delegate?.inputDidReleaseVertical()
            }
        }
    }

    private func dominant(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        abs(a) >= abs(b) ? a : b
    }

    private func resetAxes() {
        if horizontal != .none {
            horizontal = .none
            delegate?.inputDidReleaseHorizontal()
        }
        if vertical != .none {
            vertical = .none
            delegate?.inputDidReleaseVertical()
        }
    }

    private func notifyConnection() {
        onConnectionChange?(isConnected)
    }
}
