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
/// - D-pad и левый стик по X → горизонтальная ось (влево / вправо);
/// - D-pad и левый стик по Y → вертикальная ось (вверх / вниз, лестница);
/// - кнопка ✕ (cross на DualSense, A на Xbox) → прыжок.
///
/// Как и экранный джойстик, геймпад отдаёт *аналоговый* вектор: чем сильнее
/// отклонён стик, тем выше доля скорости. D-pad как цифровая крестовина даёт
/// полное отклонение по нажатой стороне.
@MainActor
final class GamepadInput {

    weak var delegate: GameInputDelegate?

    /// Вызывается при изменении состояния подключения: `true` — есть хотя бы
    /// один пригодный геймпад. Сцена прячет/показывает экранные кнопки.
    var onConnectionChange: ((Bool) -> Void)?

    /// Та же чистая математика, что и у экранного джойстика. Оси контроллера
    /// уже нормированы, поэтому радиус = 1. Мёртвая зона побольше — у физических
    /// стиков заметнее дрейф.
    private let stick = AnalogStick(radius: 1, deadZone: 0.2)

    // Последний отправленный вектор — события шлём только при изменении,
    // а не на каждый «дрожащий» отсчёт оси внутри мёртвой зоны.
    private var lastDirection: CGVector = .zero

    private var observers: [NSObjectProtocol] = []

    /// Есть ли подключённый пригодный геймпад с расширенным профилем.
    var isConnected: Bool {
        GCController.controllers().contains(where: Self.isRealGamepad)
    }

    /// Отсекает виртуальный контроллер, который iOS Simulator всегда подсовывает
    /// сам (`vendorName == "Gamepad"`, мостит клавиатуру хоста). На реальном
    /// устройстве его не существует, поэтому фильтр включён только в симуляторе —
    /// в продакшене поведение не меняется. Без него экранное управление было бы
    /// навсегда скрыто в симуляторе, как будто подключён настоящий геймпад.
    private static func isRealGamepad(_ controller: GCController) -> Bool {
        guard controller.extendedGamepad != nil else { return false }
        #if targetEnvironment(simulator)
        if controller.vendorName == "Gamepad" { return false }
        #endif
        return true
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
        // (В GameController ось Y направлена вверх — это совпадает с нашим
        // соглашением «вверх = положительный».)
        let x = dominant(CGFloat(pad.dpad.xAxis.value), CGFloat(pad.leftThumbstick.xAxis.value))
        let y = dominant(CGFloat(pad.dpad.yAxis.value), CGFloat(pad.leftThumbstick.yAxis.value))

        let direction = stick.direction(for: CGVector(dx: x, dy: y))
        sendDirection(direction)
    }

    private func dominant(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        abs(a) >= abs(b) ? a : b
    }

    /// Отправляет вектор делегату, только если он реально изменился.
    private func sendDirection(_ direction: CGVector) {
        guard direction != lastDirection else { return }
        lastDirection = direction
        delegate?.inputDidUpdateDirection(horizontal: direction.dx, vertical: direction.dy)
    }

    private func resetAxes() {
        sendDirection(.zero)
    }

    private func notifyConnection() {
        onConnectionChange?(isConnected)
    }
}
