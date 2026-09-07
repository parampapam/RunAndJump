//
//  LevelValidationTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
@testable import RunAndJump

@Suite("LevelValidation — проверки каталога и уровня")
struct LevelValidationTests {

    // MARK: - Что лежит в проекте

    @Test("Каждый каталог в проекте безупречен")
    func shippedCatalogsAreClean() {
        for catalog in StyleCatalogs.all {
            #expect(LevelValidation.issues(in: catalog).isEmpty,
                    "\(catalog.id.rawValue): \(LevelValidation.issues(in: catalog))")
        }
    }

    @Test("Каждый уровень в проекте безупречен")
    func shippedLevelsAreClean() throws {
        for level in Levels.all {
            let catalog = try #require(StyleCatalogs.catalog(for: level.style),
                                       "\(level.name): нет каталога стиля \(level.style.rawValue)")
            let issues = LevelValidation.issues(in: level, catalog: catalog)
            #expect(issues.isEmpty, "\(level.name): \(issues)")
        }
    }

    // MARK: - Каталог

    @Test("Пустое имя механической роли — находка")
    func emptyTerrainRoleIsReported() {
        let broken = Fixtures.catalog(groundTop: "")
        #expect(LevelValidation.issues(in: broken) == [.emptyTextureName(role: "terrain.groundTop")])
    }

    @Test("Разное число кадров у плиток одной записи — находка")
    func frameCountMismatchIsReported() {
        let broken = Fixtures.catalog(decorations: [
            .torch: DecorationEntry(tiles: [
                DecorationTile(column: 0, row: 0, frames: ["a0", "a1"]),
                DecorationTile(column: 0, row: 1, frames: ["b0"]),
            ]),
        ])
        #expect(LevelValidation.issues(in: broken) == [.frameCountMismatch(.torch)])
    }

    @Test("Запись без плиток — находка")
    func emptyEntryIsReported() {
        let broken = Fixtures.catalog(decorations: [.torch: DecorationEntry(tiles: [])])
        #expect(LevelValidation.issues(in: broken) == [.frameCountMismatch(.torch)])
    }

    @Test("Плитка с одинаковым числом кадров у всех ячеек — не находка")
    func matchingFrameCountsAreFine() {
        let good = Fixtures.catalog(decorations: [
            .torch: DecorationEntry(tiles: [
                DecorationTile(column: 0, row: 0, frames: ["a0", "a1"]),
                DecorationTile(column: 0, row: 1, frames: ["b0", "b1"]),
            ]),
        ])
        #expect(LevelValidation.issues(in: good).isEmpty)
    }

    // MARK: - Уровень

    @Test("Опечатка в идентификаторе декорации — находка")
    func unknownDecorationIsReported() {
        let origin = TileCoordinate(x: 3, y: 1)
        let level = Fixtures.level(decorations: [DecorationDescriptor(id: .torch, origin: origin)])
        #expect(LevelValidation.issues(in: level, catalog: Fixtures.catalog())
                == [.unknownDecoration(.torch, at: origin)])
    }

    @Test("Объект за границей уровня — находка")
    func objectOutsideLevelIsReported() {
        let level = Fixtures.level(portal: TileCoordinate(x: 99, y: 1))
        #expect(LevelValidation.issues(in: level, catalog: Fixtures.catalog())
                == [.objectOutsideLevel(role: "portal", at: TileCoordinate(x: 99, y: 1))])
    }

    @Test("Флаг на земле опору имеет")
    func checkpointOnGroundHasFooting() {
        let level = Fixtures.level(checkpoints: [CheckpointDescriptor(origin: TileCoordinate(x: 5, y: 1))])
        #expect(LevelValidation.issues(in: level, catalog: Fixtures.catalog()).isEmpty)
    }

    @Test("Флаг на платформе опору имеет")
    func checkpointOnPlatformHasFooting() {
        let level = Fixtures.level(
            platforms: [PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 4, y: 2.75),
                                                          size: TileSize(width: 3, height: 0.25)))],
            checkpoints: [CheckpointDescriptor(origin: TileCoordinate(x: 5, y: 3))]
        )
        #expect(LevelValidation.issues(in: level, catalog: Fixtures.catalog()).isEmpty)
    }

    @Test("Флаг в воздухе опоры не имеет")
    func checkpointInTheAirIsReported() {
        let level = Fixtures.level(checkpoints: [CheckpointDescriptor(origin: TileCoordinate(x: 5, y: 4))])
        #expect(LevelValidation.issues(in: level, catalog: Fixtures.catalog())
                == [.checkpointWithoutFooting(index: 0)])
    }

    @Test("Флаг над озером опоры не имеет — земля там вырезана")
    func checkpointOverHazardIsReported() {
        let level = Fixtures.level(
            hazards: [HazardDescriptor(kind: .water,
                                       rect: TileRect(origin: TileCoordinate(x: 4, y: 0),
                                                      size: TileSize(width: 2, height: 1)))],
            checkpoints: [CheckpointDescriptor(origin: TileCoordinate(x: 5, y: 1))]
        )
        #expect(LevelValidation.issues(in: level, catalog: Fixtures.catalog())
                == [.checkpointWithoutFooting(index: 0)])
    }

    // MARK: - Фон

    @Test("Сегмент, которого стиль не умеет рисовать, — находка")
    func backgroundSegmentMissingFromTheCatalogIsReported() {
        // У фикстуры есть холмы и облака, но нет стены интерьера: наземный
        // стиль, выложивший фон пещерной стеной, получил бы молчаливую пустоту.
        let level = Fixtures.level(background: BackgroundDescriptor(
            fill: .solid,
            horizon: BackgroundStrip(segments: [.hills, .interior], widthInTiles: 8),
            sky: BackgroundStrip(segments: [.clouds], widthInTiles: 10),
            horizonLineInTiles: 4
        ))

        #expect(LevelValidation.issues(in: level, catalog: Fixtures.catalog())
                == [.backgroundSegmentWithoutTexture(role: "background.horizon[1]")])
    }

    @Test("Пустой сегмент гряды — это узор, а не находка")
    func blankHorizonSegmentIsNotReported() {
        // `.fill` не рисует ничего **по замыслу** — это разрыв в гряде. Тем он
        // и отличается от слоя, которого у стиля просто нет.
        let level = Fixtures.level(background: BackgroundDescriptor(
            fill: .solid,
            horizon: BackgroundStrip(segments: [.hills, .fill], widthInTiles: 8),
            sky: BackgroundStrip(segments: [], widthInTiles: 10),
            horizonLineInTiles: 4
        ))

        #expect(LevelValidation.issues(in: level, catalog: Fixtures.catalog()).isEmpty)
    }

    @Test("Подземный фон против подземного каталога находок не даёт")
    func interiorBackgroundMatchesAnInteriorCatalog() {
        let level = Fixtures.level(background: BackgroundDescriptor(
            fill: .solid,
            horizon: BackgroundStrip(segments: [.interior], widthInTiles: 28.5),
            sky: BackgroundStrip(segments: [], widthInTiles: 10),
            horizonLineInTiles: 10
        ))
        let underground = Fixtures.catalog(background: BackgroundNames(fill: "fill",
                                                                       interior: "wall"))

        #expect(LevelValidation.issues(in: level, catalog: underground).isEmpty)
    }
}

// MARK: - Фикстуры

private extension DecorationID {
    /// Декорации, которой нет ни в одном каталоге игры, — для проверок «а если
    /// автор опечатался».
    static let torch = DecorationID("torch")
}

private enum Fixtures {

    static func catalog(groundTop: String = "ground",
                        background: BackgroundNames = BackgroundNames(fill: "fill",
                                                                      hills: "hills",
                                                                      mountains: "mountains",
                                                                      clouds: "clouds"),
                        decorations: [DecorationID: DecorationEntry] = [:]) -> StyleCatalog {
        StyleCatalog(
            id: LevelStyleID("fixture"),
            atlases: ["Fixture"],
            terrain: TerrainNames(
                groundTop: groundTop,
                platformLeft: "pl", platformMiddle: "pm", platformRight: "pr",
                ladderBottom: "lb", ladderMiddle: "lm",
                ladderTop: "lt", ladderTop75: "lt75", ladderTop50: "lt50", ladderTop25: "lt25"
            ),
            background: background,
            skyColor: RGBColor(red: 0, green: 0, blue: 0),
            decorations: decorations
        )
    }

    /// Фон фикстуры — гряда холмов и облака, то есть ровно те слои, которые
    /// `Fixtures.catalog()` умеет рисовать.
    static let background = BackgroundDescriptor(
        fill: .solid,
        horizon: BackgroundStrip(segments: [.hills], widthInTiles: 8),
        sky: BackgroundStrip(segments: [.clouds], widthInTiles: 10),
        horizonLineInTiles: 4
    )

    static func level(platforms: [PlatformDescriptor] = [],
                      hazards: [HazardDescriptor] = [],
                      checkpoints: [CheckpointDescriptor] = [],
                      decorations: [DecorationDescriptor] = [],
                      background: BackgroundDescriptor = Fixtures.background,
                      portal: TileCoordinate = TileCoordinate(x: 10, y: 1)) -> LevelConfiguration {
        LevelConfiguration(
            name: "Fixture",
            style: LevelStyleID("fixture"),
            sceneSize: CGSize(width: 1334, height: 750),
            levelWidthInTiles: 20,
            levelHeightInTiles: 10,
            playerStart: TileCoordinate(x: 1, y: 1),
            groundHeight: WorldMetrics.tileSize,
            background: background,
            platforms: platforms,
            movingPlatforms: [],
            ladders: [],
            hazards: hazards,
            enemies: [],
            pickups: [],
            checkpoints: checkpoints,
            decorations: decorations,
            portal: portal
        )
    }
}
