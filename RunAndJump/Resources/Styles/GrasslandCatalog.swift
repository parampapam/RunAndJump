//
//  GrasslandCatalog.swift
//  RunAndJump
//

import Foundation

/// Стиль «луг» — то, чем нарисованы все нынешние уровни. Тот же арт, что и
/// раньше, но записанный данными: раскладки декораций переехали сюда из
/// `DecorationTiles` (закрытого `switch` из 18 веток), имена ландшафта — из
/// `TextureName`.
enum GrasslandCatalog {

    static let catalog = StyleCatalog(
        id: .grassland,
        // Три атласа, а не один: земля и декорации в `Grassland`, планки
        // платформ и лестница — в своих. Перекладывать ассеты ради формы
        // каталога незачем, порядок поиска имени задаёт список.
        atlases: ["Grassland"],
        terrain: TerrainNames(
            groundTop: "grassland_ground_top",
            platformLeft: "grassland_platform_left",
            platformMiddle: "grassland_platform_middle",
            platformRight: "grassland_platform_right",
            ladderBottom: "grassland_ladder_bottom",
            ladderMiddle: "grassland_ladder_middle",
            ladderTop: "grassland_ladder_top",
            ladderTop75: "grassland_ladder_top_90px",
            ladderTop50: "grassland_ladder_top_60px",
            ladderTop25: "grassland_ladder_top_30px"
        ),
        background: BackgroundNames(
            fill: "bg_fill_day",
            hills: "bg_hills",
            mountains: "bg_mountains",
            clouds: "bg_clouds"
        ),
        // Ровно цвет картинки `bg_fill_day` (#B7CAF4). Совпадение обязательное:
        // этим цветом залиты края фоновых изображений, и разойдись они — стал
        // бы виден прямоугольник заливки.
        skyColor: RGBColor(red: 183 / 255, green: 202 / 255, blue: 244 / 255),
        decorations: decorations
    )

    // MARK: - Декорации

    /// Все украшения луга. Каждая запись — список плиток; многоплиточные
    /// (деревья, большие кусты) собираются из ячеек сетки: `column` вправо,
    /// `row` вверх от нижнего-левого угла декорации.
    private static let decorations: [DecorationID: DecorationEntry] = [
        .purpleFlower: DecorationEntry(tiles: [tile("grassland_flower_purple")]),
        .yellowFlower: DecorationEntry(tiles: [tile("grassland_flower_yellow")]),
        .whiteFlower: DecorationEntry(tiles: [tile("grassland_flower_white")]),
        .pinkFlower: DecorationEntry(tiles: [tile("grassland_flower_pink")]),

        .mushroom1: DecorationEntry(tiles: [tile("grassland_mushroom_1")]),
        .mushroom2: DecorationEntry(tiles: [tile("grassland_mushroom_2")]),

        .darkTree: DecorationEntry(tiles: [
            tile("grassland_tree_dark_bottom"),
            tile("grassland_tree_dark_top", row: 1),
        ]),
        .tallDarkTree: DecorationEntry(tiles: [
            tile("grassland_tree_trunk"),
            tile("grassland_tree_dark_bottom", row: 1),
            tile("grassland_tree_dark_top", row: 2),
        ]),
        .lightTree: DecorationEntry(tiles: [
            tile("grassland_tree_light_bottom"),
            tile("grassland_tree_light_top", row: 1),
        ]),
        .tallLightTree: DecorationEntry(tiles: [
            tile("grassland_tree_trunk"),
            tile("grassland_tree_light_bottom", row: 1),
            tile("grassland_tree_light_top", row: 2),
        ]),

        .bigDarkBush: DecorationEntry(tiles: [
            tile("grassland_brush_big_dark_left"),
            tile("grassland_brush_big_dark_middle", column: 1),
            tile("grassland_brush_big_dark_right", column: 2),
        ]),
        .bigLightBush: DecorationEntry(tiles: [
            tile("grassland_brush_big_light_left"),
            tile("grassland_brush_big_light_middle", column: 1),
            tile("grassland_brush_big_light_right", column: 2),
        ]),
        .smallDarkBush: DecorationEntry(tiles: [tile("grassland_brush_small_dark")]),
        .smallLightBush: DecorationEntry(tiles: [tile("grassland_brush_small_light")]),

        .leftArrow: DecorationEntry(tiles: [tile("grassland_arrow_left")]),
        .rightArrow: DecorationEntry(tiles: [tile("grassland_arrow_right")]),

        .shortDarkGrass: DecorationEntry(tiles: [tile("grassland_grass_short_dark")]),
        .shortLightGrass: DecorationEntry(tiles: [tile("grassland_grass_short_light")]),
        .tallDarkGrass: DecorationEntry(tiles: [tile("grassland_grass_tall_dark")]),
        .tallLightGrass: DecorationEntry(tiles: [tile("grassland_grass_tall_light")]),
    ]

    /// Статичная плитка: один кадр в ячейке сетки.
    private static func tile(_ name: String, column: Int = 0, row: Int = 0) -> DecorationTile {
        DecorationTile(column: column, row: row, frames: [name])
    }
}

/// Имена декораций луга для кода и тестов. Уровни в файлах (шаг 6) сошлются на
/// те же декорации строками — здесь именно удобные имена, а не отдельный
/// реестр.
///
/// Имена живут рядом со своим каталогом, а не в модели: идентификаторы локальны
/// стилю. Захоти другой стиль такое же имя в Swift — он берёт своё
/// (`dungeonTorch`) или обращается строкой; общего пространства имён у стилей
/// нет по построению.
extension DecorationID {
    static let purpleFlower = DecorationID("flower_purple")
    static let yellowFlower = DecorationID("flower_yellow")
    static let whiteFlower = DecorationID("flower_white")
    static let pinkFlower = DecorationID("flower_pink")

    static let mushroom1 = DecorationID("mushroom_1")
    static let mushroom2 = DecorationID("mushroom_2")

    static let darkTree = DecorationID("tree_dark")
    static let tallDarkTree = DecorationID("tree_dark_tall")
    static let lightTree = DecorationID("tree_light")
    static let tallLightTree = DecorationID("tree_light_tall")

    static let bigDarkBush = DecorationID("bush_dark_big")
    static let bigLightBush = DecorationID("bush_light_big")
    static let smallDarkBush = DecorationID("bush_dark_small")
    static let smallLightBush = DecorationID("bush_light_small")

    static let leftArrow = DecorationID("arrow_left")
    static let rightArrow = DecorationID("arrow_right")

    static let shortDarkGrass = DecorationID("grass_dark_short")
    static let shortLightGrass = DecorationID("grass_light_short")
    static let tallDarkGrass = DecorationID("grass_dark_tall")
    static let tallLightGrass = DecorationID("grass_light_tall")
}
