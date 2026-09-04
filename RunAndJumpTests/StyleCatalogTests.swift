//
//  StyleCatalogTests.swift
//  RunAndJumpTests
//

import Testing
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

    @Test("Стиль луга знает все декорации, расставленные в уровнях")
    func grasslandKnowsEveryDecorationUsedByLevels() throws {
        let catalog = try #require(StyleCatalogs.catalog(for: .grassland))
        for level in Levels.all where level.style == .grassland {
            for decoration in level.decorations {
                #expect(catalog.decorations[decoration.id] != nil,
                        "\(level.name): нет декорации \(decoration.id.rawValue)")
            }
        }
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
