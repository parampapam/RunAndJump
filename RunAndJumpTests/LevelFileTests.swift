//
//  LevelFileTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
import Foundation
@testable import RunAndJump

@Suite("LevelFile — уровень из файла JSON5")
struct LevelFileTests {

    // MARK: - Разбор

    @Test("Минимальный файл: обязательные поля, списки пусты")
    func minimalFileDecodes() throws {
        let level = try decode(Fixture.minimal())

        #expect(level.name == "Test")
        #expect(level.style == .grassland)
        #expect(level.sceneSize == Fixture.sceneSize)
        #expect(level.levelWidthInTiles == 6)
        #expect(level.levelHeightInTiles == 8)
        #expect(level.playerStart == TileCoordinate(x: 1, y: 1))
        #expect(level.portal == TileCoordinate(x: 4, y: 1))
        #expect(level.terrain == TerrainMap("""
        ..++..
        ######
        """))
        #expect(level.background == BackgroundDescriptor(
            fill: .solid,
            horizon: BackgroundStrip(segments: [.hills, .fill], widthInTiles: 8),
            sky: BackgroundStrip(segments: [], widthInTiles: 12),
            horizonLineInTiles: 5))
        #expect(level.platforms.isEmpty)
        #expect(level.movingPlatforms.isEmpty)
        #expect(level.ladders.isEmpty)
        #expect(level.hazards.isEmpty)
        #expect(level.enemies.isEmpty)
        #expect(level.pickups.isEmpty)
        #expect(level.checkpoints.isEmpty)
        #expect(level.decorations.isEmpty)
    }

    @Test("Объекты переводятся в описания модели один к одному")
    func objectsDecode() throws {
        let level = try decode(Fixture.minimal(extra: """
        "platforms": [{ "at": [1, 2.75], "size": [3, 0.25] }],
        "movingPlatforms": [{
          "from": [1, 3.75], "to": [4, 3.75], "size": [2, 0.25], "speed": 90,
          "stops": [{ "progress": 0, "duration": 0.6 }, { "progress": 0.5, "duration": 1 }],
        }],
        "ladders": [{ "at": [4.5, 1], "height": 2.25 }],
        "hazards": [{ "kind": "lava", "at": [2, 0], "size": [2, 1] }],
        "enemies": [
          { "kind": "plant", "at": [2, 1] },
          { "kind": "crab", "at": [1, 1], "patrol": { "leftX": 0, "rightX": 4, "speed": 100 } },
        ],
        "pickups": [{ "kind": "health", "at": [1, 1.25] }, { "kind": "coin.gold", "at": [2, 1.25] }],
        "checkpoints": [{ "at": [3, 1] }],
        "decorations": [{ "id": "flower_yellow", "at": [5, 1] }],
        """))

        #expect(level.platforms == [
            PlatformDescriptor(rect: TileRect(origin: TileCoordinate(x: 1, y: 2.75),
                                              size: TileSize(width: 3, height: 0.25))),
        ])
        #expect(level.movingPlatforms == [
            MovingPlatformDescriptor(size: TileSize(width: 2, height: 0.25),
                                     start: TileCoordinate(x: 1, y: 3.75),
                                     end: TileCoordinate(x: 4, y: 3.75),
                                     speed: 90,
                                     stops: [.start(0.6), .at(0.5, 1)]),
        ])
        #expect(level.ladders == [LadderDescriptor(origin: TileCoordinate(x: 4.5, y: 1), height: 2.25)])
        #expect(level.hazards == [
            HazardDescriptor(kind: .lava, rect: TileRect(origin: TileCoordinate(x: 2, y: 0),
                                                         size: TileSize(width: 2, height: 1))),
        ])
        #expect(level.enemies == [
            .stationary(.plant, at: TileCoordinate(x: 2, y: 1)),
            .patrolling(.crab, at: TileCoordinate(x: 1, y: 1), leftX: 0, rightX: 4, speed: 100),
        ])
        #expect(level.pickups == [
            PickupDescriptor(origin: TileCoordinate(x: 1, y: 1.25), kind: .health),
            PickupDescriptor(origin: TileCoordinate(x: 2, y: 1.25), kind: .coin(.gold)),
        ])
        #expect(level.checkpoints == [CheckpointDescriptor(origin: TileCoordinate(x: 3, y: 1))])
        #expect(level.decorations == [DecorationDescriptor(id: DecorationID("flower_yellow"),
                                                           origin: TileCoordinate(x: 5, y: 1))])
    }

    @Test("JSON5: комментарии и запятая после последнего элемента")
    func json5IsAccepted() throws {
        let level = try decode("""
        // Комментарий перед документом.
        {
          /* и блочный */ "format": 1,
          "name": "Test", // и в конце строки
          "style": "grassland",
          "size": [6, 8],
          "player": [1, 1],
          "portal": [4, 1],
          "terrain": ["######",],
          "background": {
            "horizonLine": 5,
            "horizon": { "segments": ["hills"], "width": 8 },
            "sky": { "segments": [], "width": 12 },
          },
        }
        """)
        #expect(level.name == "Test")
    }

    // MARK: - Каждое имя в файле читается

    @Test("Каждый вид врага доступен файлам", arguments: EnemyKind.allCases)
    func everyEnemyKindHasAName(kind: EnemyKind) throws {
        let name = String(describing: kind)
        let level = try decode(Fixture.minimal(extra: #""enemies": [{ "kind": "\#(name)", "at": [1, 1] }],"#))
        #expect(level.enemies.first?.kind == kind)
    }

    @Test("Каждый вид озера доступен файлам", arguments: HazardKind.allCases)
    func everyHazardKindHasAName(kind: HazardKind) throws {
        let name = String(describing: kind)
        let level = try decode(Fixture.minimal(extra: #""hazards": [{ "kind": "\#(name)", "at": [1, 0], "size": [1, 1] }],"#))
        #expect(level.hazards.first?.kind == kind)
    }

    @Test("Каждое достоинство монеты доступно файлам", arguments: CoinTier.allCases)
    func everyCoinTierHasAName(tier: CoinTier) throws {
        let name = "coin.\(String(describing: tier))"
        let level = try decode(Fixture.minimal(extra: #""pickups": [{ "kind": "\#(name)", "at": [1, 1] }],"#))
        #expect(level.pickups.first?.kind == .coin(tier))
    }

    @Test("Каждый сегмент фона доступен файлам")
    func everyBackgroundSegmentHasAName() throws {
        let horizon = HorizonSegment.allCases.map { #""\#(String(describing: $0))""# }.joined(separator: ", ")
        let sky = SkySegment.allCases.map { #""\#(String(describing: $0))""# }.joined(separator: ", ")
        let level = try decode(Fixture.minimal(background: """
        { "horizonLine": 5,
          "horizon": { "segments": [\(horizon)], "width": 8 },
          "sky": { "segments": [\(sky)], "width": 12 } }
        """))
        #expect(level.background.horizon.segments == HorizonSegment.allCases)
        #expect(level.background.sky.segments == SkySegment.allCases)
    }

    // MARK: - Ошибки называют место

    @Test("Незнакомый ключ — ошибка, а не молчаливый пропуск")
    func unknownKeyIsRejected() {
        let error = decodeError(Fixture.minimal(extra: """
        "enemies": [{ "kind": "crab", "at": [1, 1], "patorl": { "leftX": 0, "rightX": 4, "speed": 100 } }],
        """))
        #expect(error?.path == "enemies[0].patorl")
        #expect(error?.message.contains("незнакомый ключ") == true)
    }

    @Test("Незнакомый ключ на верхнем уровне — тоже ошибка")
    func unknownTopLevelKeyIsRejected() {
        #expect(decodeError(Fixture.minimal(extra: #""enemys": [],"#))?.path == "enemys")
    }

    @Test("Незнакомый вид врага — ошибка со списком допустимых")
    func unknownEnemyKindIsRejected() {
        let error = decodeError(Fixture.minimal(extra: #""enemies": [{ "kind": "crabb", "at": [1, 1] }],"#))
        #expect(error?.path == "enemies[0].kind")
        #expect(error?.message.contains("«crabb»") == true)
        #expect(error?.message.contains("crab, imp") == true)
    }

    @Test("Незнакомая награда — ошибка")
    func unknownPickupKindIsRejected() {
        let error = decodeError(Fixture.minimal(extra: #""pickups": [{ "kind": "coin.platinum", "at": [1, 1] }],"#))
        #expect(error?.path == "pickups[0].kind")
    }

    @Test("Нет обязательного поля — ошибка с его именем")
    func missingRequiredFieldIsRejected() {
        let file = Fixture.minimal().replacingOccurrences(of: #""portal": [4, 1],"#, with: "")
        let error = decodeError(file)
        #expect(error?.path == "portal")
        #expect(error?.message == "обязательное поле отсутствует")
    }

    @Test("Точка не из двух чисел — ошибка")
    func malformedPointIsRejected() {
        let file = Fixture.minimal().replacingOccurrences(of: #""player": [1, 1],"#, with: #""player": [1, 1, 1],"#)
        #expect(decodeError(file)?.path == "player")
    }

    @Test("Незнакомый символ рельефа — ошибка со строкой картинки")
    func unknownTerrainSymbolIsRejected() {
        let error = decodeError(Fixture.minimal(terrain: "[\"..x...\", \"######\"]"))
        #expect(error?.path == "terrain[0]")
        #expect(error?.message.contains("«x»") == true)
    }

    @Test("Строки рельефа разной длины — ошибка")
    func raggedTerrainIsRejected() {
        #expect(decodeError(Fixture.minimal(terrain: "[\"......\", \"#####\"]"))?.path == "terrain[1]")
    }

    @Test("Чужая версия формата — ошибка до разбора полей")
    func unsupportedFormatIsRejected() {
        let file = Fixture.minimal().replacingOccurrences(of: #""format": 1,"#, with: #""format": 2, "future": true,"#)
        let error = decodeError(file)
        #expect(error?.path == "format")
        #expect(error?.message.contains("версия формата 2") == true)
    }

    @Test("Не JSON5 вовсе — ошибка без пути")
    func brokenSyntaxIsRejected() {
        let error = decodeError(#"{ "format": 1, "#)
        #expect(error?.path == "")
        #expect(error?.message.hasPrefix("не читается как JSON5") == true)
    }

    @Test("Ошибка печатается с файлом и путём")
    func errorDescriptionNamesThePlace() {
        let error = LevelFileError(file: "level_01.json5", path: "enemies[1].kind", message: "плохо")
        #expect(error.description == "level_01.json5: enemies[1].kind: плохо")
    }

    // MARK: - Бандл

    @Test("Файла нет в бандле — ошибка с его именем")
    func missingBundledFileIsReported() {
        #expect(throws: LevelFileError(file: "no_such_level.json5", path: "", message: "файла нет в бандле")) {
            try LevelFile.load(named: "no_such_level", in: .main, sceneSize: Fixture.sceneSize)
        }
    }

    // MARK: - Помощники

    private func decode(_ text: String) throws -> LevelConfiguration {
        try LevelFile.decode(Data(text.utf8), sceneSize: Fixture.sceneSize)
    }

    private func decodeError(_ text: String) -> LevelFileError? {
        do {
            _ = try LevelFile.decode(Data(text.utf8), sceneSize: Fixture.sceneSize)
            return nil
        } catch {
            return error
        }
    }
}

private enum Fixture {

    static let sceneSize = CGSize(width: 1334, height: 750)

    /// Самый короткий допустимый файл; `extra` дописывается в конец документа.
    static func minimal(terrain: String = "[\"..++..\", \"######\"]",
                        background: String = """
                        { "horizonLine": 5,
                          "horizon": { "segments": ["hills", "fill"], "width": 8 },
                          "sky": { "segments": [], "width": 12 } }
                        """,
                        extra: String = "") -> String {
        """
        {
          "format": 1,
          "name": "Test",
          "style": "grassland",
          "size": [6, 8],
          "player": [1, 1],
          "portal": [4, 1],
          "terrain": \(terrain),
          "background": \(background),
          \(extra)
        }
        """
    }
}
