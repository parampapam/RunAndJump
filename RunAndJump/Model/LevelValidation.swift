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
        /// Объект стоит там, где стоять нельзя: под ним пусто или, наоборот,
        /// он сам замурован в грунте. На плоской земле промахнуться было
        /// нельзя, с рельефом — легко: поверхность у каждой колонки своя.
        case objectWithoutFooting(role: String, at: TileCoordinate)
        /// Карта рельефа не сходится с размером уровня: у́же него (в конце
        /// окажется невидимый обрыв) или выше него.
        case terrainSizeMismatch(width: Int, height: Int)
        /// Колонка грунта шириной в один тайл и выше одной клетки: у неё
        /// открыты оба бока, а плитки «левый и правый край сразу» в наборе нет.
        case terrainColumnTooNarrow(at: TileCoordinate)
        /// Диапазон патруля выходит за край площадки. Патрулирующие враги не
        /// динамические и не падают — такой враг просто поедет по воздуху.
        case patrolLeavesGround(index: Int)
        /// Уровень выложил фон сегментом, картинки для которого у его стиля нет:
        /// на этом месте молча окажется заливка.
        case backgroundSegmentWithoutTexture(role: String)
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

        // Две карты, как и в сцене: озёра вырезаны из физики и вписаны в форму.
        // Опора и патрули — вопрос физики, рисуемость колонки — вопрос формы:
        // колонка, ставшая узкой только из-за соседнего озера, рисуется
        // прекрасно, потому что вода ей соседом и остаётся.
        let hazardRects = level.hazards.map(\.rect)
        let terrain = level.terrain.carving(hazardRects)
        let shape = level.terrain.filling(hazardRects)

        issues += backgroundWithoutTextures(level, catalog: catalog)
        issues += outsideLevel(level)
        issues += terrainFitsLevel(level)
        issues += unrenderableColumns(in: shape)
        issues += withoutFooting(level, terrain: terrain)
        issues += patrolsLeavingGround(level, terrain: terrain)
        return issues
    }

    // MARK: - Частные проверки

    /// Все имена каталога с человекочитаемой ролью.
    ///
    /// Сами списки ролей живут рядом с полями (`TerrainNames.namedRoles`,
    /// `BackgroundNames.namedRoles`): раньше они были переписаны здесь и ещё
    /// раз в `StyleAssetsTests`, и новая роль требовала правки в трёх местах.
    ///
    /// Необязательные слои фона (`nil` — «такого слоя у стиля нет») сюда не
    /// попадают: отсутствие слоя это законный ответ, а вот **пустая строка**
    /// вместо имени — опечатка, и её надо поймать.
    private static func namedRoles(of catalog: StyleCatalog) -> [(role: String, name: String)] {
        catalog.terrain.namedRoles + catalog.background.namedRoles
    }

    /// Сегменты фона, которых стиль уровня не умеет рисовать.
    ///
    /// Слои фона необязательны, и это правильно: у пещеры нет холмов. Но
    /// «стиль без холмов» и «уровень, выложивший фон холмами» вместе дают
    /// молчаливую пустоту, а раньше такое ловил компилятор. Ловим здесь.
    private static func backgroundWithoutTextures(_ level: LevelConfiguration,
                                                  catalog: StyleCatalog) -> [Issue] {
        let background = level.background
        var issues: [Issue] = []

        for (index, segment) in background.horizon.segments.enumerated()
        where !segment.isBlank && catalog.background.name(for: segment) == nil {
            issues.append(.backgroundSegmentWithoutTexture(role: "background.horizon[\(index)]"))
        }

        for (index, segment) in background.sky.segments.enumerated()
        where catalog.background.name(for: segment) == nil {
            issues.append(.backgroundSegmentWithoutTexture(role: "background.sky[\(index)]"))
        }

        return issues
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

    /// Карта рельефа против размера уровня.
    ///
    /// Ширина обязана совпадать: карта у́же уровня оставила бы в конце обрыв,
    /// которого не видно в описании. Высота — только не больше: карта вправе
    /// описывать столько рядов, сколько нужно рельефу, всё выше неё пусто.
    private static func terrainFitsLevel(_ level: LevelConfiguration) -> [Issue] {
        let terrain = level.terrain
        guard CGFloat(terrain.width) != level.levelWidthInTiles
                || CGFloat(terrain.height) > level.levelHeightInTiles else { return [] }
        return [.terrainSizeMismatch(width: terrain.width, height: terrain.height)]
    }

    /// Колонки, которых набор плиток не умеет рисовать.
    ///
    /// Это ровно тот случай, в котором `TerrainTiling` вынужден выбирать
    /// наугад: у клетки заняты верх и низ и открыты оба бока, а плитки с двумя
    /// краями сразу в наборе нет. Полка в одну клетку сюда не попадает — у неё
    /// открыт верх, и она честно рисуется серединой.
    private static func unrenderableColumns(in terrain: TerrainMap) -> [Issue] {
        var issues: [Issue] = []
        for y in 0..<terrain.height {
            for x in 0..<terrain.width where terrain.isOccupied(x: x, y: y) {
                // Соседей считаем так же, как раскладка: иначе колонка, узкая
                // только на вид, попадала бы в находки.
                let kind = terrain.cell(x: x, y: y)
                guard terrain.isNeighbour(x: x, y: y + 1, of: kind),
                      terrain.isNeighbour(x: x, y: y - 1, of: kind),
                      !terrain.isNeighbour(x: x - 1, y: y, of: kind),
                      !terrain.isNeighbour(x: x + 1, y: y, of: kind)
                else { continue }
                issues.append(.terrainColumnTooNarrow(at: TileCoordinate(x: CGFloat(x), y: CGFloat(y))))
            }
        }
        return issues
    }

    /// Объекты, под которыми нет опоры.
    ///
    /// Проверяются те, что **ставят игрока**: старт уровня и флаги (флаг — это
    /// и место возрождения). Промах здесь роняет игрока сквозь уровень или
    /// оставляет его в воздухе, тогда как висящая в воздухе декорация — просто
    /// некрасиво.
    ///
    /// Неподвижные враги не проверяются намеренно: растение стоит на земле, а
    /// оса висит в воздухе, и различить их можно только новым свойством
    /// `EnemyKind`. Заводить его ради проверки — не та цена.
    private static func withoutFooting(_ level: LevelConfiguration, terrain: TerrainMap) -> [Issue] {
        var issues: [Issue] = []

        func check(_ role: String, _ origin: TileCoordinate) {
            guard !hasFooting(at: origin, in: level, terrain: terrain) else { return }
            issues.append(.objectWithoutFooting(role: role, at: origin))
        }

        check("playerStart", level.playerStart)
        for (index, checkpoint) in level.checkpoints.enumerated() {
            check("checkpoints[\(index)]", checkpoint.origin)
        }
        return issues
    }

    /// Патрули, выходящие за край площадки.
    ///
    /// Враг не динамический: сойдя с края, он не упадёт, а поедет по воздуху.
    /// Проверяется вся полоса, которую заметает его тело, — от левого края
    /// диапазона до правого плюс ширина врага.
    private static func patrolsLeavingGround(_ level: LevelConfiguration,
                                             terrain: TerrainMap) -> [Issue] {
        level.enemies.enumerated().compactMap { index, enemy in
            guard case .patrolling(let leftX, let rightX, _) = enemy.behavior else { return nil }

            let row = Int(enemy.origin.y.rounded(.down))
            let from = Int(leftX.rounded(.down))
            let to = Int((rightX + ObjectSize.enemy.width).rounded(.up)) - 1
            guard from <= to else { return nil }

            let grounded = (from...to).allSatisfy { terrain.supportsStanding(x: $0, y: row) }
            return grounded ? nil : .patrolLeavesGround(index: index)
        }
    }

    /// Можно ли стоять в этой точке: на рельефе (`TerrainMap.supportsStanding`)
    /// или на верху площадки.
    ///
    /// Подвижные платформы опорой не считаются: они уезжают, и объект,
    /// поставленный «на» такую платформу, окажется в воздухе через секунду.
    private static func hasFooting(at origin: TileCoordinate,
                                   in level: LevelConfiguration,
                                   terrain: TerrainMap) -> Bool {
        let standing = terrain.supportsStanding(x: Int(origin.x.rounded(.down)),
                                                y: Int(origin.y.rounded(.down)))
        if standing { return true }

        return level.platforms.contains { platform in
            origin.y == platform.rect.origin.y + platform.rect.size.height
                && platform.rect.xSpan.contains(origin.x)
        }
    }
}
