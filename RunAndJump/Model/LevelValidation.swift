//
//  LevelValidation.swift
//  RunAndJump
//

import CoreGraphics

/// Проверки уровня и каталога стиля. Чистые функции, без SpriteKit.
///
/// Нужны потому, что открытый идентификатор отнял у компилятора возможность
/// ловить опечатки: `DecorationID("flwoer_purple")` компилируется прекрасно.
/// Замена компилятору — эта функция и тест, который прогоняет через неё всё,
/// что лежит в проекте.
///
/// Политика разная по категориям, и это решение о том, что считать фатальным:
/// - **пустая механическая роль** — уровень не собрать, без плитки платформы
///   играть нельзя;
/// - **незнакомая декорация** — в DEBUG падение (автор видит опечатку сразу),
///   в релизе пропуск: терять уровень из-за лишнего цветочка нельзя.
///
/// Сама функция ничего не решает — она только перечисляет находки. Что с ними
/// делать, решают вызывающие: тест валит сборку, сцена пропускает декорацию.
enum LevelValidation {

    enum Issue: Equatable {
        /// Уровень ссылается на декорацию, которой нет в каталоге его стиля.
        case unknownDecoration(DecorationID, at: TileCoordinate)
        /// У плиток одной записи разное число кадров — анимация разъедется.
        case frameCountMismatch(DecorationID)
        /// Роль каталога названа пустой строкой.
        case emptyTextureName(role: String)
        /// Объект стоит за пределами уровня — его просто не будет видно.
        case objectOutsideLevel(role: String, at: TileCoordinate)
        /// Флаг стоит там, где игроку не на чем стоять: он же место возрождения.
        case checkpointWithoutFooting(index: Int)
    }

    // MARK: - Каталог

    /// Проверки самого каталога — от уровня не зависят.
    static func issues(in catalog: StyleCatalog) -> [Issue] {
        var issues: [Issue] = []

        for (role, name) in namedRoles(of: catalog) where name.isEmpty {
            issues.append(.emptyTextureName(role: role))
        }

        // Порядок обхода словаря не определён, а список находок хочется
        // стабильным — иначе один и тот же каталог даёт разный вывод.
        for id in catalog.decorations.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard let entry = catalog.decorations[id] else { continue }

            // Пустая запись и плитка без кадров — тот же дефект, что и разное
            // число кадров: нарисовать по такой записи нечего.
            let frameCounts = Set(entry.tiles.map(\.frames.count))
            if entry.tiles.isEmpty || frameCounts.count != 1 || frameCounts.contains(0) {
                issues.append(.frameCountMismatch(id))
            }

            for tile in entry.tiles {
                for frame in tile.frames where frame.isEmpty {
                    issues.append(.emptyTextureName(role: "\(id.rawValue)[\(tile.column),\(tile.row)]"))
                }
            }
        }

        return issues
    }

    // MARK: - Уровень

    /// Проверки уровня против каталога его стиля.
    static func issues(in level: LevelConfiguration, catalog: StyleCatalog) -> [Issue] {
        var issues: [Issue] = []

        for decoration in level.decorations where catalog.decorations[decoration.id] == nil {
            issues.append(.unknownDecoration(decoration.id, at: decoration.origin))
        }

        issues += outsideLevel(level)
        issues += checkpointsWithoutFooting(level)
        return issues
    }

    // MARK: - Частные проверки

    /// Все обязательные имена каталога с человекочитаемой ролью.
    private static func namedRoles(of catalog: StyleCatalog) -> [(String, String)] {
        let terrain = catalog.terrain
        let background = catalog.background
        return [
            ("terrain.groundTop", terrain.groundTop),
            ("terrain.platformLeft", terrain.platformLeft),
            ("terrain.platformMiddle", terrain.platformMiddle),
            ("terrain.platformRight", terrain.platformRight),
            ("terrain.ladderBottom", terrain.ladderBottom),
            ("terrain.ladderMiddle", terrain.ladderMiddle),
            ("terrain.ladderTop", terrain.ladderTop),
            ("terrain.ladderTop75", terrain.ladderTop75),
            ("terrain.ladderTop50", terrain.ladderTop50),
            ("terrain.ladderTop25", terrain.ladderTop25),
            ("background.fill", background.fill),
            ("background.hills", background.hills),
            ("background.mountains", background.mountains),
            ("background.clouds", background.clouds),
        ]
    }

    /// Объекты, вышедшие за границы уровня. Проверяется нижний-левый угол:
    /// объект, начавшийся за краем, не виден целиком, а не наполовину.
    private static func outsideLevel(_ level: LevelConfiguration) -> [Issue] {
        var issues: [Issue] = []

        func check(_ role: String, _ origin: TileCoordinate) {
            guard origin.x < 0 || origin.y < 0
                    || origin.x > level.levelWidthInTiles
                    || origin.y > level.levelHeightInTiles else { return }
            issues.append(.objectOutsideLevel(role: role, at: origin))
        }

        check("playerStart", level.playerStart)
        check("portal", level.portal)
        for (index, enemy) in level.enemies.enumerated() { check("enemies[\(index)]", enemy.origin) }
        for (index, pickup) in level.pickups.enumerated() { check("pickups[\(index)]", pickup.origin) }
        for (index, item) in level.decorations.enumerated() { check("decorations[\(index)]", item.origin) }
        for (index, item) in level.checkpoints.enumerated() { check("checkpoints[\(index)]", item.origin) }
        for (index, item) in level.platforms.enumerated() { check("platforms[\(index)]", item.rect.origin) }
        for (index, item) in level.ladders.enumerated() { check("ladders[\(index)]", item.origin) }
        for (index, item) in level.hazards.enumerated() { check("hazards[\(index)]", item.rect.origin) }

        return issues
    }

    /// Флаги, под которыми нет опоры.
    ///
    /// Координата флага — это и место появления игрока, поэтому ставить его
    /// можно только туда, где игрок может стоять: на землю (её верх) или на
    /// платформу. Земля под озером вырезана, так что флаг над озером опоры не
    /// имеет — игрок возродился бы прямо в воде.
    private static func checkpointsWithoutFooting(_ level: LevelConfiguration) -> [Issue] {
        let groundTop = level.groundHeight / WorldMetrics.tileSize
        let ground = GroundLayout.segments(levelWidthInTiles: level.levelWidthInTiles,
                                           gaps: level.hazards.map(\.rect.xSpan))

        return level.checkpoints.enumerated().compactMap { index, checkpoint in
            let x = checkpoint.origin.x
            let y = checkpoint.origin.y

            let onGround = y == groundTop && ground.contains { $0.contains(x) }
            let onPlatform = level.platforms.contains { platform in
                y == platform.rect.origin.y + platform.rect.size.height
                    && platform.rect.xSpan.contains(x)
            }

            return onGround || onPlatform ? nil : .checkpointWithoutFooting(index: index)
        }
    }
}
