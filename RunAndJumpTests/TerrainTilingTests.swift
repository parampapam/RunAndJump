//
//  TerrainTilingTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 20.09.2026.
//

import Testing
import CoreGraphics
@testable import RunAndJump

struct TerrainTilingTests {

    private func part(_ x: Int, _ y: Int, in map: TerrainMap) -> TerrainTiling.Part {
        TerrainTiling.part(x: x, y: y, in: map)
    }

    // MARK: - Девятислайс

    @Test("Массив 3×3 раскладывается девятислайсом")
    func solidBlockIsANineSlice() {
        // Массив висит в воздухе, поэтому виден со всех четырёх сторон.
        let map = TerrainMap("""
        .###.
        .###.
        .###.
        .....
        """)

        #expect(part(1, 3, in: map) == .topLeft)
        #expect(part(2, 3, in: map) == .topMiddle)
        #expect(part(3, 3, in: map) == .topRight)

        #expect(part(1, 2, in: map) == .left)
        #expect(part(2, 2, in: map) == .inside)
        #expect(part(3, 2, in: map) == .right)

        #expect(part(1, 1, in: map) == .bottomLeft)
        #expect(part(2, 1, in: map) == .bottomMiddle)
        #expect(part(3, 1, in: map) == .bottomRight)
    }

    // MARK: - Порядок правил

    @Test("Верх важнее низа: у пола в один тайл открыты обе грани")
    func topWinsOverBottom() {
        // Пол высотой ровно в тайл — случай не экзотический, а единственный,
        // каким земля была до появления рельефа.
        let floor = TerrainMap("###")

        #expect(part(0, 0, in: floor) == .topLeft)
        #expect(part(1, 0, in: floor) == .topMiddle)
        #expect(part(2, 0, in: floor) == .topRight)
    }

    @Test("Одиночная клетка получает ровные торцы, а не скруглённые")
    func lonelyCellIsFlatOnBothSides() {
        #expect(part(0, 0, in: TerrainMap("#")) == .topMiddle)
    }

    @Test("Полка в один тайл — это верхняя плитка, а не нижняя")
    func oneTileLedgeIsASurface() {
        let map = TerrainMap("""
        .#.
        ...
        """)
        #expect(part(1, 1, in: map) == .topMiddle)
    }

    // MARK: - Уступ

    @Test("Толща рядом с началом поверхности справа закрывает уступ")
    func thicknessBeforeASurfaceIsAStep() {
        // Слева массив в два ряда, справа его поверхность на ряд ниже.
        let map = TerrainMap("""
        ##..
        ####
        """)

        // (1, 0) — толща: сверху занято, снизу край уровня, оба бока заняты.
        // Справа от неё поверхность, поэтому полоса покрытия заворачивается
        // в её правый верхний угол.
        #expect(part(1, 0, in: map) == .insideBeforeTop)
        #expect(part(2, 0, in: map) == .topMiddle)
    }

    @Test("Толща рядом с концом поверхности слева закрывает уступ зеркально")
    func thicknessAfterASurfaceIsAStep() {
        let map = TerrainMap("""
        ..##
        ####
        """)

        #expect(part(2, 0, in: map) == .insideAfterTop)
        #expect(part(1, 0, in: map) == .topMiddle)
    }

    @Test("Глухая толща остаётся глухой")
    func thicknessAwayFromSurfacesIsPlain() {
        let map = TerrainMap("""
        #####
        #####
        #####
        """)
        #expect(part(2, 1, in: map) == .inside)
    }

    @Test("Поверхность, упирающаяся в более высокий массив, не скругляется")
    func surfaceMeetingAWallStaysFlush() {
        // Скругление здесь оставило бы щель между поверхностью и стеной:
        // полосу продолжает плитка уступа соседнего массива.
        let map = TerrainMap("""
        ##..
        ####
        """)
        #expect(part(2, 0, in: map) == .topMiddle)
    }

    // MARK: - Берег озера

    @Test("Грунт на берегу озера рисуется серединой, а не торцом")
    func groundNextToALakeIsFlush() {
        // Озеро вырезано из грунта (физика) и вписано обратно в форму: выбирая
        // плитку, берег обязан считать воду соседом. Иначе он возьмёт торцевую
        // плитку — а у торцов края скруглены и прозрачны, и между землёй и
        // водой откроется щель.
        let lake = TileRect(origin: TileCoordinate(x: 2, y: 0),
                            size: TileSize(width: 2, height: 1))
        let terrain = TerrainMap.floor(width: 6, height: 2)
        let solid = terrain.carving([lake])
        let shape = terrain.filling([lake])

        // Клетки берега в карте физики остались, а клетки озера — нет.
        #expect(solid.isSolid(x: 1, y: 0))
        #expect(!solid.isSolid(x: 2, y: 0))

        // И всё же торцами они не становятся.
        #expect(part(1, 0, in: shape) == .topMiddle)
        #expect(part(4, 0, in: shape) == .topMiddle)

        // Без вписывания озера было бы ровно то, на что жалуются глаза.
        #expect(part(1, 0, in: solid) == .topRight)
        #expect(part(4, 0, in: solid) == .topLeft)
    }

    @Test("Стенка глубокого озера рисуется толщей, а не боковой гранью")
    func deepLakeShoreIsPlainThickness() {
        // Озеро в два ряда: без вписывания его стенка стала бы открытым боком
        // массива — со скруглением и прозрачным краем на всю глубину.
        let lake = TileRect(origin: TileCoordinate(x: 2, y: 0),
                            size: TileSize(width: 2, height: 2))
        let terrain = TerrainMap.floor(width: 6, height: 3, thicknessInTiles: 3)

        #expect(part(1, 1, in: terrain.carving([lake])) == .right)
        #expect(part(1, 1, in: terrain.filling([lake])) == .inside)
    }

    // MARK: - Границы уровня

    @Test("Массив у нижнего края уровня не получает низа")
    func groundAtTheBottomOfTheLevelHasNoUnderside() {
        // Ниже нижнего края земля считается сплошной, иначе на самом краю
        // экрана появился бы скруглённый низ.
        let map = TerrainMap("""
        ####
        ####
        """)
        #expect(part(1, 0, in: map) == .inside)
        #expect(part(0, 0, in: map) == .left)
    }

    @Test("Массив у боковой границы уровня получает край")
    func terrainAtTheSideOfTheLevelIsCapped() {
        let map = TerrainMap("""
        ####
        ####
        """)
        #expect(part(0, 1, in: map) == .topLeft)
        #expect(part(3, 1, in: map) == .topRight)
    }

    // MARK: - Каталог

    @Test("Каталог стиля отвечает на каждую роль непустым именем")
    func everyCatalogAnswersEveryPart() {
        for catalog in StyleCatalogs.all {
            for role in TerrainTiling.Part.allCases {
                #expect(!catalog.terrain.name(for: role).isEmpty,
                        "\(catalog.id.rawValue): нет имени для \(role)")
            }
        }
    }

    @Test("Роли не делят между собой одну текстуру")
    func partsDoNotShareTextures() {
        for catalog in StyleCatalogs.all {
            let names = TerrainTiling.Part.allCases.map { catalog.terrain.name(for: $0) }
            #expect(Set(names).count == names.count,
                    "\(catalog.id.rawValue): одна текстура на несколько ролей грунта")
        }
    }
}
