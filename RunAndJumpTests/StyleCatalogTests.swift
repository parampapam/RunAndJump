//
//  StyleCatalogTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
@testable import RunAndJump

@Suite("StyleCatalog — каталоги стилей как данные")
struct StyleCatalogTests {

    @Test("У каждой записи все плитки имеют одинаковое число кадров")
    func everyEntryHasTilesInStep() {
        for catalog in StyleCatalogs.all {
            for (id, entry) in catalog.decorations {
                let counts = Set(entry.tiles.map(\.frames.count))
                #expect(counts.count == 1,
                        "\(catalog.id.rawValue)/\(id.rawValue): плитки с разным числом кадров — \(counts.sorted())")
            }
        }
    }

    @Test("У каждой записи есть хотя бы одна плитка и хотя бы один кадр")
    func everyEntryDrawsSomething() {
        for catalog in StyleCatalogs.all {
            for (id, entry) in catalog.decorations {
                #expect(!entry.tiles.isEmpty, "\(catalog.id.rawValue)/\(id.rawValue): нет плиток")
                #expect(entry.tiles.allSatisfy { !$0.frames.isEmpty },
                        "\(catalog.id.rawValue)/\(id.rawValue): плитка без кадров")
            }
        }
    }

    @Test("Каталог находится по идентификатору стиля")
    func catalogIsFoundByStyleID() throws {
        let catalog = try #require(StyleCatalogs.catalog(for: .grassland))
        #expect(catalog.id == .grassland)
        #expect(StyleCatalogs.catalog(for: LevelStyleID("нет такого")) == nil)
    }

    @Test("Стиль каждого уровня знает все расставленные в нём декорации")
    func everyLevelStyleKnowsItsDecorations() throws {
        for level in Levels.all {
            let catalog = try #require(StyleCatalogs.catalog(for: level.style),
                                       "\(level.name): нет каталога стиля \(level.style.rawValue)")
            for decoration in level.decorations {
                #expect(catalog.decorations[decoration.id] != nil,
                        "\(level.name) (\(level.style.rawValue)): нет декорации \(decoration.id.rawValue)")
            }
        }
    }

    @Test("Наборы декораций у стилей не пересекаются")
    func stylesDoNotShareDecorationIdentifiers() {
        // Идентификаторы декораций локальны стилю: `"mushrooms_1"` у пещеры и
        // `"mushroom_1"` у луга — разные записи в разных каталогах. Совпадение
        // сырых имён само по себе не ошибка, но оно означает, что кто-то начал
        // строить общий реестр декораций, — а его в этой конструкции быть не
        // должно. Пересечение здесь ловится раньше, чем на нём что-то построят.
        let grassland = Set(GrasslandCatalog.catalog.decorations.keys.map(\.rawValue))
        let cave = Set(CaveCatalog.catalog.decorations.keys.map(\.rawValue))

        #expect(grassland.intersection(cave).isEmpty,
                "общие идентификаторы: \(grassland.intersection(cave).sorted())")
    }

    @Test("Запись с одним кадром на плитку статична, с несколькими — анимирована")
    func animationFollowsFrameCount() {
        let still = DecorationEntry(tiles: [DecorationTile(column: 0, row: 0, frames: ["a"])])
        #expect(!still.isAnimated)
        // Слой по умолчанию — задний: декорация украшает сцену, а не заслоняет игрока.
        #expect(still.layer == .back)

        let torch = DecorationEntry(tiles: [DecorationTile(column: 0, row: 0, frames: ["a", "b"])],
                                    frameDuration: 0.15,
                                    randomizePhase: true,
                                    layer: .front)
        #expect(torch.isAnimated)
        #expect(torch.layer == .front)
    }

    @Test("Все нынешние декорации луга статичны и лежат за игроком")
    func grasslandDecorationsAreStillAndBehindThePlayer() {
        for (id, entry) in GrasslandCatalog.catalog.decorations {
            #expect(!entry.isAnimated, "\(id.rawValue): арт луга статичен")
            #expect(entry.layer == .back, "\(id.rawValue): цветы и кусты — задний план")
        }
    }

    @Test("У пещеры вместо неба стена, и наоборот")
    func caveHasAnInteriorInsteadOfSky() {
        let cave = CaveCatalog.catalog.background
        #expect(cave.interior != nil, "пещере нечем нарисовать стену")
        #expect(cave.hills == nil && cave.mountains == nil && cave.clouds == nil,
                "под землёй не бывает ни гряды, ни облаков")

        let grassland = GrasslandCatalog.catalog.background
        #expect(grassland.interior == nil, "у луга нет стены интерьера")

        // Сегмент разрешается в имя только у того стиля, который его умеет.
        #expect(cave.name(for: HorizonSegment.interior) != nil)
        #expect(cave.name(for: HorizonSegment.hills) == nil)
        #expect(grassland.name(for: HorizonSegment.interior) == nil)
        // Пустой сегмент не рисует ничего ни у кого — и это не пропажа слоя.
        #expect(HorizonSegment.fill.isBlank)
        #expect(!HorizonSegment.interior.isBlank)
    }

    @Test("Части платформы и лестницы разрешаются в имена текстур")
    func terrainResolvesEveryPart() {
        let terrain = GrasslandCatalog.catalog.terrain
        #expect(terrain.name(for: PlatformTiling.Part.left) == terrain.platformLeft)
        #expect(terrain.name(for: PlatformTiling.Part.middle) == terrain.platformMiddle)
        #expect(terrain.name(for: PlatformTiling.Part.right) == terrain.platformRight)

        #expect(terrain.name(for: LadderTiling.Part.bottom) == terrain.ladderBottom)
        #expect(terrain.name(for: LadderTiling.Part.middle) == terrain.ladderMiddle)
        #expect(terrain.name(for: LadderTiling.Part.top(fraction: 1)) == terrain.ladderTop)
        #expect(terrain.name(for: LadderTiling.Part.top(fraction: 0.75)) == terrain.ladderTop75)
        #expect(terrain.name(for: LadderTiling.Part.top(fraction: 0.5)) == terrain.ladderTop50)
        #expect(terrain.name(for: LadderTiling.Part.top(fraction: 0.25)) == terrain.ladderTop25)
    }
}
