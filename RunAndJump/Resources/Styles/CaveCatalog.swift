//
//  CaveCatalog.swift
//  RunAndJump
//

import Foundation

/// Стиль «пещера» — второй стиль игры и первая настоящая проверка всей
/// конструкции: набор декораций у него **заведомо другой**, чем у луга
/// (кристаллы и сталактиты вместо цветов и деревьев), поэтому одинаковыми
/// раскладками отделаться не вышло.
///
/// В коде ради него не изменилось ничего, кроме одного места: `LevelStyleID` →
/// каталог в `StyleCatalogs.all`. Перевести уровень на пещеру = поправить поле
/// `style` в его `LevelConfiguration`.
///
/// ## Чем пещера отличается от луга по существу
///
/// **Под землёй нет неба.** Вместо гряды холмов и облаков — сплошная стена
/// (`HorizonSegment.interior`), а линия горизонта поднята до потолка уровня,
/// так что верхняя полоса пустует. Поэтому `hills`, `mountains` и `clouds` у
/// каталога `nil`: это не забытые поля, а честный ответ «такого слоя у стиля
/// нет». Уровень, который всё же выложит фон холмами, поймает
/// `LevelValidation.backgroundSegmentWithoutTexture`.
enum CaveCatalog {

    static let catalog = StyleCatalog(
        id: .cave,
        atlases: ["Cave"],
        terrain: TerrainNames(
            groundTop: "cave_ground_top_middle",
            // Каменная плита со скруглёнными торцами. Арт занимает **верхнюю
            // половину** квадратного кадра — того же требования, что у луга и
            // замка, и по той же причине: `PlatformSkin` рисует спрайт в целый
            // тайл и вешает его от верха площадки вниз. Плитка, нарисованная на
            // всю высоту кадра, свисала бы на целый тайл ниже того, по чему
            // игрок ходит.
            platformLeft: "cave_platform_left",
            platformMiddle: "cave_platform_middle",
            platformRight: "cave_platform_right",
            ladderBottom: "cave_ladder_bottom",
            ladderMiddle: "cave_ladder_middle",
            ladderTop: "cave_ladder_top",
            ladderTop75: "cave_ladder_top_90px",
            ladderTop50: "cave_ladder_top_60px",
            ladderTop25: "cave_ladder_top_30px"
        ),
        background: BackgroundNames(
            fill: "bg_fill_cave",
            interior: "bg_cave_interior"
        ),
        // Ровно цвет картинки `bg_fill_cave` (#3A2D25) — он же основной тон
        // `bg_cave_interior`. Совпадение обязательное: этим цветом видно дно
        // ям под озёрами, где грунта за жидкостью нет.
        skyColor: RGBColor(red: 58 / 255, green: 45 / 255, blue: 37 / 255),
        decorations: decorations
    )

    // MARK: - Декорации

    /// Украшения пещеры. Все статичные — в пещерном арте анимированных плиток
    /// нет (факелы с кадрами есть только у замка). Анимация записи не требует:
    /// плитка с одним кадром статична, с несколькими — крутится.
    private static let decorations: [DecorationID: DecorationEntry] = [
        // Крупные кристаллы — заметные акценты, ставятся поодиночке.
        .caveBigBlueCrystal: DecorationEntry(tiles: [tile("cave_crystal_big_blue")]),
        .caveBigPinkCrystal: DecorationEntry(tiles: [tile("cave_crystal_big_pink")]),
        .caveBigPurpleCrystal: DecorationEntry(tiles: [tile("cave_crystal_big_purple")]),
        .caveBigRedCrystal: DecorationEntry(tiles: [tile("cave_crystal_big_red")]),
        .caveBigYellowCrystal: DecorationEntry(tiles: [tile("cave_crystal_big_yellow")]),

        // Мелкие — россыпью вдоль пола.
        .caveSmallBlueCrystal: DecorationEntry(tiles: [tile("cave_crystal_small_blue")]),
        .caveSmallPinkCrystal: DecorationEntry(tiles: [tile("cave_crystal_small_pink")]),
        .caveSmallPurpleCrystal: DecorationEntry(tiles: [tile("cave_crystal_small_purple")]),
        .caveSmallRedCrystal: DecorationEntry(tiles: [tile("cave_crystal_small_red")]),
        .caveSmallYellowCrystal: DecorationEntry(tiles: [tile("cave_crystal_small_yellow")]),

        .caveMushrooms1: DecorationEntry(tiles: [tile("cave_mushrooms_1")]),
        .caveMushrooms2: DecorationEntry(tiles: [tile("cave_mushrooms_2")]),
        .caveMushrooms3: DecorationEntry(tiles: [tile("cave_mushrooms_3")]),

        .caveBigBush: DecorationEntry(tiles: [
            tile("cave_brush_big_left"),
            tile("cave_brush_big_middle", column: 1),
            tile("cave_brush_big_right", column: 2),
        ]),
        .caveSmallBush: DecorationEntry(tiles: [tile("cave_brush_small")]),

        // Бугры на полу — рельеф, а не предмет: ставятся на землю.
        .caveBigHillock1: DecorationEntry(tiles: [tile("cave_hillock_big_1")]),
        .caveBigHillock2: DecorationEntry(tiles: [tile("cave_hillock_big_2")]),
        .caveBigHillock3: DecorationEntry(tiles: [tile("cave_hillock_big_3")]),
        .caveMediumHillock1: DecorationEntry(tiles: [tile("cave_hillock_medium_1")]),
        .caveMediumHillock2: DecorationEntry(tiles: [tile("cave_hillock_medium_2")]),
        .caveMediumHillock3: DecorationEntry(tiles: [tile("cave_hillock_medium_3")]),
        .caveSmallHillock: DecorationEntry(tiles: [tile("cave_hillock_small")]),

        // Сталактит растёт с потолка, сталагмит — с пола; куда ставить, знает
        // уровень, каталог знает только картинку.
        .caveStalactite: DecorationEntry(tiles: [tile("cave_stalactite")]),
        .caveStalagmite: DecorationEntry(tiles: [tile("cave_stalagmite")]),
    ]

    /// Статичная плитка: один кадр в ячейке сетки.
    private static func tile(_ name: String, column: Int = 0, row: Int = 0) -> DecorationTile {
        DecorationTile(column: column, row: row, frames: [name])
    }
}

/// Имена декораций пещеры для кода и тестов.
///
/// Сами идентификаторы (`rawValue`) **локальны стилю** и потому не префиксованы:
/// `"mushrooms_1"` у пещеры и `"mushroom_1"` у луга — разные записи в разных
/// каталогах, общего пространства имён у них нет.
///
/// А вот константы Swift живут в одном расширении `DecorationID` на всю игру,
/// поэтому здесь префикс нужен: `.caveSmallBush` рядом с `.smallLightBush` луга.
/// Издержка терпимая и даже полезная — уровень луга, написавший `.caveStalagmite`,
/// виден в диффе сразу, ещё до того как за него возьмётся `LevelValidation`.
extension DecorationID {
    static let caveBigBlueCrystal = DecorationID("crystal_blue_big")
    static let caveBigPinkCrystal = DecorationID("crystal_pink_big")
    static let caveBigPurpleCrystal = DecorationID("crystal_purple_big")
    static let caveBigRedCrystal = DecorationID("crystal_red_big")
    static let caveBigYellowCrystal = DecorationID("crystal_yellow_big")

    static let caveSmallBlueCrystal = DecorationID("crystal_blue_small")
    static let caveSmallPinkCrystal = DecorationID("crystal_pink_small")
    static let caveSmallPurpleCrystal = DecorationID("crystal_purple_small")
    static let caveSmallRedCrystal = DecorationID("crystal_red_small")
    static let caveSmallYellowCrystal = DecorationID("crystal_yellow_small")

    static let caveMushrooms1 = DecorationID("mushrooms_1")
    static let caveMushrooms2 = DecorationID("mushrooms_2")
    static let caveMushrooms3 = DecorationID("mushrooms_3")

    static let caveBigBush = DecorationID("bush_big")
    static let caveSmallBush = DecorationID("bush_small")

    static let caveBigHillock1 = DecorationID("hillock_big_1")
    static let caveBigHillock2 = DecorationID("hillock_big_2")
    static let caveBigHillock3 = DecorationID("hillock_big_3")
    static let caveMediumHillock1 = DecorationID("hillock_medium_1")
    static let caveMediumHillock2 = DecorationID("hillock_medium_2")
    static let caveMediumHillock3 = DecorationID("hillock_medium_3")
    static let caveSmallHillock = DecorationID("hillock_small")

    static let caveStalactite = DecorationID("stalactite")
    static let caveStalagmite = DecorationID("stalagmite")
}
