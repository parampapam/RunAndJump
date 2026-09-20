//
//  TerrainLayoutTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 20.09.2026.
//

import Testing
import CoreGraphics
@testable import RunAndJump

struct TerrainLayoutTests {

    private func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> TileRect {
        TileRect(origin: TileCoordinate(x: x, y: y), size: TileSize(width: width, height: height))
    }

    @Test("Пустая карта не даёт тел")
    func emptyMapHasNoBodies() {
        #expect(TerrainLayout.bodies(of: TerrainMap("....\n....")).isEmpty)
    }

    @Test("Сплошной пол — одно тело на всю ширину")
    func flatFloorIsOneBody() {
        #expect(TerrainLayout.bodies(of: TerrainMap.floor(width: 45, height: 16))
                == [rect(0, 0, 45, 1)])
    }

    @Test("Проём в полу делит его надвое")
    func gapSplitsTheFloor() {
        let map = TerrainMap.floor(width: 5, height: 2)
            .carving([TileRect(origin: TileCoordinate(x: 2, y: 0),
                               size: TileSize(width: 1, height: 1))])

        #expect(TerrainLayout.bodies(of: map) == [rect(0, 0, 2, 1), rect(3, 0, 2, 1)])
    }

    @Test("Ряды с одинаковыми границами склеиваются по вертикали")
    func equalRunsMergeVertically() {
        let map = TerrainMap("""
        .##.
        .##.
        ####
        """)

        #expect(TerrainLayout.bodies(of: map) == [rect(0, 0, 4, 1), rect(1, 1, 2, 2)])
    }

    @Test("Ряды с разными границами остаются разными телами")
    func differentRunsDoNotMerge() {
        let map = TerrainMap("""
        .#..
        ###.
        """)

        #expect(TerrainLayout.bodies(of: map) == [rect(0, 0, 3, 1), rect(1, 1, 1, 1)])
    }

    @Test("Два массива в одном ряду — два тела")
    func separateRunsInARowAreSeparateBodies() {
        #expect(TerrainLayout.bodies(of: TerrainMap("##.##"))
                == [rect(0, 0, 2, 1), rect(3, 0, 2, 1)])
    }

    @Test("Холм на полу — пол одним телом и холм вторым")
    func hillOnTheFloor() {
        let map = TerrainMap("""
        ..........
        ..####....
        ##########
        """)

        #expect(TerrainLayout.bodies(of: map) == [rect(0, 0, 10, 1), rect(2, 1, 4, 1)])
    }

    @Test("Массив у верхнего края карты закрывается её высотой")
    func bodyTouchingTheTopIsClosed() {
        #expect(TerrainLayout.bodies(of: TerrainMap("##\n##")) == [rect(0, 0, 2, 2)])
    }

    /// Главная гарантия склейки: если по поверхности можно пробежать, она
    /// принадлежит одному телу. Иначе игрок спотыкается на шве.
    @Test("Непрерывная поверхность принадлежит одному телу")
    func walkableSurfaceBelongsToASingleBody() {
        let map = TerrainMap("""
        .....###..
        ..##..###.
        ##########
        """)
        let bodies = TerrainLayout.bodies(of: map)

        // Поверхность нижнего ряда непрерывна по всей ширине — значит нижний
        // ряд целиком лежит в одном теле, а не нарезан под каждым выступом.
        let floor = bodies.filter { $0.origin.y == 0 }
        #expect(floor == [rect(0, 0, 10, 1)])
    }

    // MARK: - Проходимый грунт

    @Test("Проходимый грунт тел не даёт")
    func passableGroundHasNoBodies() {
        #expect(TerrainLayout.bodies(of: TerrainMap("++++")).isEmpty)
    }

    @Test("Проходимый грунт даёт одностороннюю опору по верху участка")
    func passableGroundGivesASurface() {
        let map = TerrainMap("""
        ..++..
        ######
        """)

        #expect(TerrainLayout.surfaces(of: map)
                == [TerrainSurface(y: 2, xSpan: 2...4)])
        // Пол при этом остаётся обычным телом.
        #expect(TerrainLayout.bodies(of: map) == [rect(0, 0, 6, 1)])
    }

    @Test("Опора одна на участок, а не на клетку")
    func surfaceSpansTheWholeRun() {
        // Иначе игрок спотыкался бы на швах между соседними рёбрами — та же
        // причина, по которой склеиваются тела.
        #expect(TerrainLayout.surfaces(of: TerrainMap("++++"))
                == [TerrainSurface(y: 1, xSpan: 0...4)])
    }

    @Test("Разорванные участки дают разные опоры")
    func separatePassableRunsGiveSeparateSurfaces() {
        #expect(TerrainLayout.surfaces(of: TerrainMap("++.++"))
                == [TerrainSurface(y: 1, xSpan: 0...2),
                    TerrainSurface(y: 1, xSpan: 3...5)])
    }

    @Test("Опора есть только у открытого сверху ряда")
    func onlyTheExposedRowGivesASurface() {
        // У нижних рядов холма ребра нет: изнутри холм не держит.
        let map = TerrainMap("""
        ++
        ++
        ++
        """)
        #expect(TerrainLayout.surfaces(of: map) == [TerrainSurface(y: 3, xSpan: 0...2)])
    }

    @Test("Проходимая клетка под сплошной опоры не даёт")
    func passableUnderSolidGivesNoSurface() {
        // Сверху её накрывает тело сплошного грунта, а лишнее ребро внутри
        // массива ловило бы игрока изнутри.
        #expect(TerrainLayout.surfaces(of: TerrainMap("#\n+")).isEmpty)
    }

    @Test("Тела покрывают ровно занятые клетки, без нахлёстов")
    func bodiesCoverExactlyTheSolidCells() {
        let map = TerrainMap("""
        ..##..
        .###..
        ######
        """)
        let bodies = TerrainLayout.bodies(of: map)

        let covered = bodies.reduce(CGFloat(0)) { $0 + $1.size.width * $1.size.height }
        var solid: CGFloat = 0
        for y in 0..<map.height {
            for x in 0..<map.width where map.isSolid(x: x, y: y) { solid += 1 }
        }
        #expect(covered == solid)

        // Нахлёст поймали бы по совпадению площади только вместе с пропуском,
        // поэтому проверяем ещё и поклеточно: каждая занятая клетка накрыта
        // ровно одним телом.
        for y in 0..<map.height {
            for x in 0..<map.width where map.isSolid(x: x, y: y) {
                let covering = bodies.filter {
                    $0.origin.x <= CGFloat(x) && CGFloat(x) < $0.origin.x + $0.size.width
                        && $0.origin.y <= CGFloat(y) && CGFloat(y) < $0.origin.y + $0.size.height
                }
                #expect(covering.count == 1)
            }
        }
    }
}
