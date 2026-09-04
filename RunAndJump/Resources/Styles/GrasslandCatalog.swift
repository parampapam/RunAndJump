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
        atlases: ["Grassland", "Platforms", "Ladder"],
        terrain: TerrainNames(
            groundTop: "grass tiles (24)",
            platformLeft: "grass tiles (52)",
            platformMiddle: "grass tiles (57)",
            platformRight: "grass tiles (6)",
            ladderBottom: "town tiles (57)",
            ladderMiddle: "town tiles (44)",
            ladderTop: "town tiles (53)",
            ladderTop75: "town tiles (53) 90px",
            ladderTop50: "town tiles (53) 60px",
            ladderTop25: "town tiles (53) 30px"
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
        .purpleFlower: DecorationEntry(tiles: [tile("grass tiles (14)")]),
        .yellowFlower: DecorationEntry(tiles: [tile("grass tiles (34)")]),
        .whiteFlower: DecorationEntry(tiles: [tile("grass tiles (49)")]),
        .pinkFlower: DecorationEntry(tiles: [tile("grass tiles (63)")]),

        .darkTree: DecorationEntry(tiles: [
            tile("grass tiles (61)"),
            tile("grass tiles (62)", row: 1),
        ]),
        .tallDarkTree: DecorationEntry(tiles: [
            tile("grass tiles (18)"),
            tile("grass tiles (61)", row: 1),
            tile("grass tiles (62)", row: 2),
        ]),
        .lightTree: DecorationEntry(tiles: [
            tile("grass tiles (39)"),
            tile("grass tiles (38)", row: 1),
        ]),
        .tallLightTree: DecorationEntry(tiles: [
            tile("grass tiles (18)"),
            tile("grass tiles (39)", row: 1),
            tile("grass tiles (38)", row: 2),
        ]),

        .bigDarkBush: DecorationEntry(tiles: [
            tile("grass tiles (54)"),
            tile("grass tiles (29)", column: 1),
            tile("grass tiles (40)", column: 2),
        ]),
        .bigLightBush: DecorationEntry(tiles: [
            tile("grass tiles (13)"),
            tile("grass tiles (30)", column: 1),
            tile("grass tiles (4)", column: 2),
        ]),
        .smallDarkBush: DecorationEntry(tiles: [tile("grass tiles (41)")]),
        .smallLightBush: DecorationEntry(tiles: [tile("grass tiles (25)")]),

        .leftArrow: DecorationEntry(tiles: [tile("grass tiles (16)")]),
        .rightArrow: DecorationEntry(tiles: [tile("grass tiles (23)")]),

        .shortDarkGrass: DecorationEntry(tiles: [tile("grass tiles (10)")]),
        .shortLightGrass: DecorationEntry(tiles: [tile("grass tiles (53)")]),
        .tallDarkGrass: DecorationEntry(tiles: [tile("grass tiles (56)")]),
        .tallLightGrass: DecorationEntry(tiles: [tile("grass tiles (35)")]),
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
