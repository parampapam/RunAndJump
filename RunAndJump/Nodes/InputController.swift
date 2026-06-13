//
//  InputController.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 29.04.2026.
//

import SpriteKit

/// Экранное управление: перетаскиваемый аналоговый джойстик слева и кнопка
/// прыжка справа.
///
/// Джойстик заменил прежнюю крестовину из четырёх кнопок. Палец тащит «шляпку»
/// в любую сторону; чем дальше отклонение от центра, тем выше доля скорости —
/// ровно так же, как стик на геймпаде. Вся математика отклонения вынесена в
/// чистый `AnalogStick`, узел отвечает только за отрисовку и касания.
final class InputController: SKNode {

    weak var delegate: GameInputDelegate?

    // MARK: Геометрия

    /// Насколько далеко от центра можно начать хват, чтобы взяться за стик
    /// было легко (чуть больше визуальной базы).
    private let grabRadius: CGFloat = 110

    /// Радиус хода «шляпки» от центра базы, точки. Совпадает с радиусом
    /// `AnalogStick` ниже — это максимальное отклонение, дающее полную скорость.
    private let stick = AnalogStick(radius: 60, deadZone: 0.12)

    private let stickCenter: CGPoint
    private let jumpCenter: CGPoint
    private let jumpRadius: CGFloat = 56

    private let stickBase: SKShapeNode
    private let stickKnob: SKShapeNode
    private let jumpButton: SKShapeNode

    // MARK: Активные касания

    // Раздельные слоты: можно одновременно вести стик и жать прыжок.
    private var movementTouch: UITouch?
    private var jumpTouch: UITouch?

    init(sceneSize: CGSize) {
        // Координаты считаются от левого нижнего угла экрана (узел туда смещён
        // сценой). Поднимаем элементы повыше, чтобы палец не лежал у самого
        // низа и не уставал.
        stickCenter = CGPoint(x: 150, y: 175)
        jumpCenter = CGPoint(x: sceneSize.width - 130, y: 165)

        stickBase = SKShapeNode(circleOfRadius: 72)
        stickBase.fillColor = .darkGray
        stickBase.strokeColor = .white
        stickBase.lineWidth = 2
        stickBase.alpha = 0.25
        stickBase.position = stickCenter

        stickKnob = SKShapeNode(circleOfRadius: 38)
        stickKnob.fillColor = .lightGray
        stickKnob.strokeColor = .white
        stickKnob.lineWidth = 2
        stickKnob.alpha = 0.5
        stickKnob.position = stickCenter

        jumpButton = SKShapeNode(circleOfRadius: jumpRadius)
        jumpButton.fillColor = .darkGray
        jumpButton.strokeColor = .white
        jumpButton.lineWidth = 2
        jumpButton.alpha = 0.3
        jumpButton.position = jumpCenter

        super.init()

        zPosition = 1000

        addChild(stickBase)
        addChild(stickKnob)
        addChild(jumpButton)
        addLabel("↑", to: jumpButton)

        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addLabel(_ text: String, to node: SKNode) {
        let label = SKLabelNode(text: text)
        label.fontSize = 28
        label.fontColor = .white
        label.alpha = 0.8
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.isUserInteractionEnabled = false
        node.addChild(label)
    }

    // MARK: - Обработка касаний

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handleTouchBegan(touch) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch == movementTouch {
            updateStick(with: touch)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handleTouchEnded(touch) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handleTouchEnded(touch) }
    }

    private func handleTouchBegan(_ touch: UITouch) {
        let location = touch.location(in: self)

        // Прыжок имеет приоритет, если палец лёг на его кнопку.
        if jumpTouch == nil, distance(from: location, to: jumpCenter) <= jumpRadius {
            jumpTouch = touch
            delegate?.inputDidPressJump()
            return
        }

        // Иначе — хват джойстика, если палец достаточно близко к базе.
        if movementTouch == nil, distance(from: location, to: stickCenter) <= grabRadius {
            movementTouch = touch
            updateStick(with: touch)
        }
    }

    private func handleTouchEnded(_ touch: UITouch) {
        if touch == movementTouch {
            movementTouch = nil
            recenterKnob()
            delegate?.inputDidUpdateDirection(horizontal: 0, vertical: 0)
        }
        if touch == jumpTouch {
            jumpTouch = nil
        }
    }

    /// Двигает «шляпку» под пальцем (в пределах радиуса) и сообщает сцене новое
    /// аналоговое направление.
    private func updateStick(with touch: UITouch) {
        let location = touch.location(in: self)
        let offset = CGVector(dx: location.x - stickCenter.x, dy: location.y - stickCenter.y)

        let knobOffset = stick.knobOffset(for: offset)
        stickKnob.position = CGPoint(x: stickCenter.x + knobOffset.dx, y: stickCenter.y + knobOffset.dy)

        let direction = stick.direction(for: offset)
        delegate?.inputDidUpdateDirection(horizontal: direction.dx, vertical: direction.dy)
    }

    private func recenterKnob() {
        stickKnob.run(.move(to: stickCenter, duration: 0.08))
    }

    private func distance(from a: CGPoint, to b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    // MARK: - Видимость

    /// Прячет/показывает экранное управление. Сцена скрывает его, когда подключён
    /// физический геймпад, и возвращает обратно при его отключении.
    func setControlsHidden(_ hidden: Bool) {
        isHidden = hidden
        isUserInteractionEnabled = !hidden
        // Если прячем во время активного хвата — снимаем удержание, иначе игрок
        // «застрянет» в движении после переключения на геймпад.
        if hidden {
            movementTouch = nil
            jumpTouch = nil
            recenterKnob()
            delegate?.inputDidUpdateDirection(horizontal: 0, vertical: 0)
        }
    }
}
