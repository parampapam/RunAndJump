//
//  TerrainMapTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 20.09.2026.
//

import Testing
import CoreGraphics
@testable import RunAndJump

struct TerrainMapTests {

    // MARK: - Разбор картинки

    @Test("Строки картинки читаются сверху вниз, а карта растёт снизу вверх")
    func pictureRowsAreReadTopDown() {
        let map = TerrainMap("""
        ..#
        ###
        """)

        #expect(map.width == 3)
        #expect(map.height == 2)
        // Нижняя строка картинки — ряд y = 0.
        #expect(map.isSolid(x: 0, y: 0))
        #expect(map.isSolid(x: 1, y: 0))
        #expect(map.isSolid(x: 2, y: 0))
        // Верхняя строка — ряд y = 1, занята только правая клетка.
        #expect(!map.isSolid(x: 0, y: 1))
        #expect(!map.isSolid(x: 1, y: 1))
        #expect(map.isSolid(x: 2, y: 1))
    }

    @Test("Пустые строки по краям картинки не считаются рядами")
    func blankEdgeLinesAreIgnored() {
        let padded = TerrainMap("\n\n##\n..\n\n")
        #expect(padded.height == 2)
        #expect(padded == TerrainMap("##\n.."))
    }

    @Test("Отступ строк картинки не влияет на карту")
    func indentationIsIgnored() {
        #expect(TerrainMap("  ##  \n  ..  ") == TerrainMap("##\n.."))
    }

    // MARK: - Границы

    @Test("Ниже нижнего края уровня земля считается сплошной")
    func belowLevelIsSolid() {
        let map = TerrainMap("..")
        #expect(map.isSolid(x: 0, y: -1))
        #expect(map.isSolid(x: 1, y: -5))
    }

    @Test("За боковыми и верхней границами пусто")
    func outsideOtherEdgesIsEmpty() {
        let map = TerrainMap("##")
        #expect(!map.isSolid(x: -1, y: 0))
        #expect(!map.isSolid(x: 2, y: 0))
        #expect(!map.isSolid(x: 0, y: 1))
    }

    // MARK: - Пол

    @Test("Пол занимает нижние ряды на всю ширину")
    func floorFillsBottomRows() {
        let map = TerrainMap.floor(width: 4, height: 3, thicknessInTiles: 2)

        for x in 0..<4 {
            #expect(map.isSolid(x: x, y: 0))
            #expect(map.isSolid(x: x, y: 1))
            #expect(!map.isSolid(x: x, y: 2))
        }
    }

    @Test("Пол в один тайл — то же, что нарисованный руками")
    func thinFloorMatchesPicture() {
        #expect(TerrainMap.floor(width: 3, height: 2) == TerrainMap("...\n###"))
    }

    // MARK: - Проёмы под озёрами

    @Test("Озеро вырезает клетки, которых касается")
    func carvingClearsCoveredCells() {
        let map = TerrainMap.floor(width: 5, height: 2)
            .carving([TileRect(origin: TileCoordinate(x: 2, y: 0),
                               size: TileSize(width: 2, height: 1))])

        #expect(map.isSolid(x: 1, y: 0))
        #expect(!map.isSolid(x: 2, y: 0))
        #expect(!map.isSolid(x: 3, y: 0))
        #expect(map.isSolid(x: 4, y: 0))
    }

    @Test("Озеро глубже одного ряда вырезает все свои ряды")
    func carvingClearsEveryRowOfTheRect() {
        let map = TerrainMap.floor(width: 4, height: 4, thicknessInTiles: 3)
            .carving([TileRect(origin: TileCoordinate(x: 1, y: 0),
                               size: TileSize(width: 1, height: 3))])

        #expect((0..<3).allSatisfy { !map.isSolid(x: 1, y: $0) })
        #expect((0..<3).allSatisfy { map.isSolid(x: 0, y: $0) })
    }

    @Test("Вырез за краем карты обрезается, а не роняет разбор")
    func carvingIsClampedToTheMap() {
        let map = TerrainMap.floor(width: 3, height: 2)
            .carving([TileRect(origin: TileCoordinate(x: -2, y: -2),
                               size: TileSize(width: 3, height: 3))])

        #expect(!map.isSolid(x: 0, y: 0))
        #expect(map.isSolid(x: 2, y: 0))
    }

    @Test("Без озёр карта остаётся прежней")
    func carvingNothingChangesNothing() {
        let map = TerrainMap.floor(width: 5, height: 3)
        #expect(map.carving([]) == map)
        #expect(map.filling([]) == map)
    }

    // MARK: - Жидкость как часть формы

    @Test("Озеро, вписанное в карту, занимает свои клетки")
    func fillingMarksCoveredCellsSolid() {
        let lake = TileRect(origin: TileCoordinate(x: 2, y: 0),
                            size: TileSize(width: 2, height: 1))
        let map = TerrainMap.floor(width: 5, height: 2).carving([lake]).filling([lake])

        #expect(map == TerrainMap.floor(width: 5, height: 2))
    }

    @Test("Вписывание занимает и те клетки, где грунта не было")
    func fillingAddsCellsThatWereEmpty() {
        let map = TerrainMap("....\n....")
            .filling([TileRect(origin: TileCoordinate(x: 1, y: 0),
                               size: TileSize(width: 2, height: 2))])

        #expect(map == TerrainMap("""
        .##.
        .##.
        """))
    }

    // MARK: - Проходимый грунт

    @Test("Проходимый грунт занимает клетку, но сплошным не считается")
    func passableIsOccupiedButNotSolid() {
        let map = TerrainMap("+#")

        #expect(map.isOccupied(x: 0, y: 0))
        #expect(!map.isSolid(x: 0, y: 0))
        #expect(map.isSolid(x: 1, y: 0))
    }

    @Test("На сплошном грунте стоят")
    func standingOnSolid() {
        let map = TerrainMap("""
        ..
        ##
        """)
        #expect(map.supportsStanding(x: 0, y: 1))
    }

    @Test("Внутри сплошного грунта не стоят — там замуровано")
    func standingInsideSolidIsImpossible() {
        let map = TerrainMap("""
        ##
        ##
        """)
        #expect(!map.supportsStanding(x: 0, y: 1))
    }

    @Test("На верху проходимого холма стоят")
    func standingOnTopOfPassable() {
        let map = TerrainMap("""
        ..
        ++
        ##
        """)
        #expect(map.supportsStanding(x: 0, y: 2))
    }

    @Test("Внутри проходимого холма стоят, если под ногами сплошной грунт")
    func standingInsidePassableOnSolidGround() {
        // Это и есть «пройти мимо холма»: игрок идёт по земле, а холм —
        // вокруг него.
        let map = TerrainMap("""
        ++
        ##
        """)
        #expect(map.supportsStanding(x: 0, y: 1))
    }

    @Test("Внутри проходимого холма не стоят, если под ногами он же")
    func standingInsidePassableOnPassableIsImpossible() {
        // Одностороннее ребро есть только у верхней клетки участка, поэтому
        // изнутри холм не держит — игрок провалится к земле.
        let map = TerrainMap("""
        ++
        ++
        ##
        """)
        #expect(!map.supportsStanding(x: 0, y: 2))
    }

    @Test("Нижний край уровня опорой не считается")
    func bottomEdgeIsNotFooting() {
        // Правило «ниже низа земля сплошная» живёт ради раскладки плиток и на
        // вопрос «можно ли тут стоять» не распространяется.
        #expect(!TerrainMap("##").supportsStanding(x: 0, y: 0))
    }
}
