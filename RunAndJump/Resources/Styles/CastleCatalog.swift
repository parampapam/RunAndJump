//
//  CastleCatalog.swift
//  RunAndJump
//

import Foundation

/// Стиль «замок» — третий стиль игры и первый, у которого декорации не только
/// стоят, но и **горят**: факел это четыре кадра в одной записи. Ради него, как
/// и ради пещеры, в коде не изменилось ничего, кроме строчки в
/// `StyleCatalogs.all`.
///
/// ## Чем замок отличается по существу
///
/// **Интерьер, как у пещеры, но кирпичный.** Неба нет: вместо гряды и облаков —
/// сплошная кладка (`HorizonSegment.interior`), поэтому `hills`, `mountains` и
/// `clouds` здесь `nil` — честный ответ «такого слоя у стиля нет», а не забытое
/// поле. Уровень, выложивший фон холмами, поймает
/// `LevelValidation.backgroundSegmentWithoutTexture`.
///
/// **Есть анимация.** У луга и пещеры все записи статичны, у замка факел —
/// четыре кадра со сдвигом фазы: два факела на одной стене не должны мигать в
/// унисон. Он же — единственная запись переднего слоя: факел висит на стене,
/// перед которой проходит игрок, и рисоваться должен поверх него.
enum CastleCatalog {

    static let catalog = StyleCatalog(
        id: .castle,
        atlases: ["Castle"],
        terrain: TerrainNames(
            groundTop: "castle_ground_top_middle",
            // Как у луга и пещеры: арт лежит в **верхней половине**
            // квадратного кадра, потому что `PlatformSkin` рисует спрайт в
            // целый тайл и вешает его от верха площадки вниз. Планка замка
            // тоньше соседских — она занимает меньше половины кадра, и это
            // законно: нельзя только выходить за неё вниз.
            platformLeft: "castle_platform_left",
            platformMiddle: "castle_platform_middle",
            platformRight: "castle_platform_right",
            ladderBottom: "castle_ladder_bottom",
            ladderMiddle: "castle_ladder_middle",
            ladderTop: "castle_ladder_top",
            ladderTop75: "castle_ladder_top_90px",
            ladderTop50: "castle_ladder_top_60px",
            ladderTop25: "castle_ladder_top_30px"
        ),
        background: BackgroundNames(
            fill: "bg_fill_castle",
            interior: "bg_castle_interior"
        ),
        // Ровно основной тон кирпича в `bg_castle_interior` (#282A2E), которым залита
        // картинка `bg_fill_castle`. Совпадение обязательное: этот цвет виден
        // выше линии горизонта и на дне ям под озёрами, где за жидкостью нет
        // грунта, — разойдись он с заливкой, стал бы виден её прямоугольник.
        skyColor: RGBColor(red: 40 / 255, green: 42 / 255, blue: 46 / 255),
        decorations: decorations
    )

    // MARK: - Декорации

    /// Украшения замка. Многоплиточные записи собираются из ячеек сетки:
    /// `column` вправо, `row` вверх от нижнего-левого угла декорации.
    private static let decorations: [DecorationID: DecorationEntry] = [
        // Факел — единственная анимированная запись во всей игре и
        // единственная на переднем слое. Фаза случайна: ряд факелов вдоль
        // стены, мигающих в такт, выглядит как гирлянда, а не как огонь.
        .castleTorch: DecorationEntry(
            tiles: [DecorationTile(column: 0, row: 0, frames: [
                "castle_torch_1", "castle_torch_2", "castle_torch_3", "castle_torch_4",
            ])],
            frameDuration: 0.12,
            randomizePhase: true,
            layer: .front
        ),

        // Мост: настил в три тайла и опоры под ним. Пролёт фиксированной
        // ширины — как большой куст у луга и пещеры; длинный мост
        // выкладывается несколькими декорациями подряд.
        .castleBridge: DecorationEntry(tiles: [
            tile("castle_bridge_bottom"),
            tile("castle_bridge_bottom", column: 1),
            tile("castle_bridge_bottom", column: 2),
            tile("castle_bridge_top_left", row: 1),
            tile("castle_bridge_top_middle", column: 1, row: 1),
            tile("castle_bridge_top_right", column: 2, row: 1),
        ]),

        // Колонна в три тайла: база, ствол, капитель.
        .castleColumn: DecorationEntry(tiles: [
            tile("castle_column_bottom"),
            tile("castle_column_middle", row: 1),
            tile("castle_column_top", row: 2),
        ]),
        .castleBrokenColumn: DecorationEntry(tiles: [tile("castle_column_broken")]),

        // Статуи-химеры на постаментах — два тайла в высоту.
        .castleChimera1: DecorationEntry(tiles: [
            tile("castle_chimera_1_bottom"),
            tile("castle_chimera_1_top", row: 1),
        ]),
        .castleChimera2: DecorationEntry(tiles: [
            tile("castle_chimera_2_bottom"),
            tile("castle_chimera_2_top", row: 1),
        ]),

        // Зубчатая стена и решётка — горизонтальные пролёты в три тайла.
        .castleWall: DecorationEntry(tiles: [
            tile("castle_wall_left"),
            tile("castle_wall_middle", column: 1),
            tile("castle_wall_right", column: 2),
        ]),
        .castleFence: DecorationEntry(tiles: [
            tile("castle_fence_left"),
            tile("castle_fence_middle", column: 1),
            tile("castle_fence_right", column: 2),
        ]),

        // Двери и проёмы. Это украшения, а не выход с уровня: выход — портал,
        // и он общий на всю игру.
        .castleWoodenDoor: DecorationEntry(tiles: [tile("castle_door_wooden")]),
        .castleIronDoor: DecorationEntry(tiles: [tile("castle_door_iron")]),
        .castleDoorway: DecorationEntry(tiles: [tile("castle_doorway")]),

        .castleBigWindow: DecorationEntry(tiles: [tile("castle_window_big")]),
        .castleSmallWindow: DecorationEntry(tiles: [tile("castle_window_small")]),
        .castleStainedGlassWindow: DecorationEntry(tiles: [tile("castle_window_stainedglass")]),

        // Знамёна висят на общем карнизе, поэтому соседние тайлы стыкуются в
        // ряд сами — отдельной записи «ряд знамён» не нужно.
        .castleBlueGonfalon: DecorationEntry(tiles: [tile("castle_gonfalon_blue")]),
        .castlePurpleGonfalon: DecorationEntry(tiles: [tile("castle_gonfalon_purple")]),
        .castleRedGonfalon: DecorationEntry(tiles: [tile("castle_gonfalon_red")]),

        // Утварь: мелочь, которой обживается пол.
        .castleHorizontalBarrel: DecorationEntry(tiles: [tile("castle_barrel_horizontal")]),
        .castleVerticalBarrel: DecorationEntry(tiles: [tile("castle_barrel_vertical")]),
        .castleBox: DecorationEntry(tiles: [tile("castle_box")]),
        .castleSign: DecorationEntry(tiles: [tile("castle_sign")]),

        .castleVase1: DecorationEntry(tiles: [tile("castle_vase_1")]),
        .castleVase2: DecorationEntry(tiles: [tile("castle_vase_2")]),
        // Вазы с растениями выше тайла — цветок отдельной плиткой сверху.
        .castleVase3: DecorationEntry(tiles: [
            tile("castle_vase_3_bottom"),
            tile("castle_vase_3_top", row: 1),
        ]),
        .castleVase4: DecorationEntry(tiles: [
            tile("castle_vase_4_bottom"),
            tile("castle_vase_4_top", row: 1),
        ]),
    ]

    /// Статичная плитка: один кадр в ячейке сетки.
    private static func tile(_ name: String, column: Int = 0, row: Int = 0) -> DecorationTile {
        DecorationTile(column: column, row: row, frames: [name])
    }
}

/// Имена декораций замка для кода и тестов.
///
/// Сами идентификаторы (`rawValue`) **локальны стилю** и потому не префиксованы,
/// а константы Swift живут в одном расширении `DecorationID` на всю игру —
/// поэтому здесь префикс нужен (`.castleWall` рядом с `.caveSmallBush`). То же
/// правило, что у пещеры.
extension DecorationID {
    static let castleTorch = DecorationID("torch")

    static let castleBridge = DecorationID("bridge")

    static let castleColumn = DecorationID("column")
    static let castleBrokenColumn = DecorationID("column_broken")

    static let castleChimera1 = DecorationID("chimera_1")
    static let castleChimera2 = DecorationID("chimera_2")

    static let castleWall = DecorationID("wall")
    static let castleFence = DecorationID("fence")

    static let castleWoodenDoor = DecorationID("door_wooden")
    static let castleIronDoor = DecorationID("door_iron")
    static let castleDoorway = DecorationID("doorway")

    static let castleBigWindow = DecorationID("window_big")
    static let castleSmallWindow = DecorationID("window_small")
    static let castleStainedGlassWindow = DecorationID("window_stainedglass")

    static let castleBlueGonfalon = DecorationID("gonfalon_blue")
    static let castlePurpleGonfalon = DecorationID("gonfalon_purple")
    static let castleRedGonfalon = DecorationID("gonfalon_red")

    static let castleHorizontalBarrel = DecorationID("barrel_horizontal")
    static let castleVerticalBarrel = DecorationID("barrel_vertical")
    static let castleBox = DecorationID("box")
    static let castleSign = DecorationID("sign")

    static let castleVase1 = DecorationID("vase_1")
    static let castleVase2 = DecorationID("vase_2")
    static let castleVase3 = DecorationID("vase_3")
    static let castleVase4 = DecorationID("vase_4")
}
