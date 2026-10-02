//
//  LevelFile.swift
//  RunAndJump
//

import CoreGraphics
import Foundation

/// Уровень из файла. Формат — **JSON5**: обычный JSON плюс комментарии и
/// запятые после последнего элемента. Уровни пишутся руками, и объяснение,
/// почему краб стоит именно здесь, должно лежать рядом с крабом.
///
/// Файл описывает то же, что `LevelConfiguration`, и в тех же единицах: тайлы,
/// нижний-левый угол, `y` вверх. Перенос уровня из кода в файл — это смена
/// синтаксиса, а не пересчёт. Исключение одно и то же, что у `TerrainMap`:
/// строки рельефа идут сверху вниз.
///
/// ```json5
/// {
///   "format": 1,
///   "name": "Level 1",
///   "style": "grassland",
///   "size": [45, 16],
///   "player": [1, 1],
///   "portal": [42, 1],
///   "terrain": ["..##..", "######"],
///   "background": {
///     "horizonLine": 5,
///     "horizon": { "segments": ["hills", "fill"], "width": 8 },
///     "sky": { "segments": ["clouds"], "width": 12 },
///   },
///   "enemies": [
///     { "kind": "crab", "at": [3, 1], "patrol": { "leftX": 2, "rightX": 5, "speed": 100 } },
///   ],
/// }
/// ```
///
/// Чего в файле нет, то общее для всех уровней: размер сцены и заливка фона.
/// Списки объектов необязательны — пропущенный значит пустой.
///
/// **Разбор строгий.** `Codable` по умолчанию молча пропускает незнакомые
/// ключи, и опечатка `"patorl"` превратила бы краба в неподвижного без единого
/// сообщения. Здесь незнакомый ключ — ошибка, а каждая ошибка называет место:
/// `enemies[1].kind: незнакомое значение «crabb»`.
enum LevelFile {

    /// Расширение файлов уровней в бандле.
    static let fileExtension = "json5"

    /// Версия формата. Файл другой версии отвергается целиком, а не читается
    /// наугад: при несовместимой правке формата номер растёт.
    static let formatVersion = 1

    /// Разбор уровня из данных файла. Чистая функция: ни бандла, ни диска.
    static func decode(_ data: Data, sceneSize: CGSize) throws(LevelFileError) -> LevelConfiguration {
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        do {
            return try decoder.decode(Document.self, from: data).configuration(sceneSize: sceneSize)
        } catch let error as DecodingError {
            throw LevelFileError(error)
        } catch {
            throw LevelFileError(path: "", message: error.localizedDescription)
        }
    }

    /// Уровень из файла `<name>.json5` в бандле. Единственное место, где формат
    /// касается ввода-вывода.
    static func load(named name: String,
                     in bundle: Bundle,
                     sceneSize: CGSize) throws(LevelFileError) -> LevelConfiguration {
        let fileName = "\(name).\(fileExtension)"
        guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
            throw LevelFileError(file: fileName, path: "", message: "файла нет в бандле")
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LevelFileError(file: fileName, path: "", message: error.localizedDescription)
        }

        do {
            return try decode(data, sceneSize: sceneSize)
        } catch {
            throw error.located(in: fileName)
        }
    }
}

/// Что не так с файлом уровня: где (`path` — как в файле, `enemies[1].kind`)
/// и что. Текст для автора уровня, а не для игрока.
struct LevelFileError: Error, Equatable, CustomStringConvertible {
    var file: String?
    let path: String
    let message: String

    init(file: String? = nil, path: String, message: String) {
        self.file = file
        self.path = path
        self.message = message
    }

    func located(in file: String) -> LevelFileError {
        LevelFileError(file: file, path: path, message: message)
    }

    var description: String {
        let place = [file, path.isEmpty ? nil : path].compactMap { $0 }.joined(separator: ": ")
        return place.isEmpty ? message : "\(place): \(message)"
    }
}

// MARK: - Документ

/// Файл целиком. Разбирается вручную, а не синтезированным `init(from:)`:
/// только так можно отвергнуть незнакомые ключи (см. `strictContainer`).
private struct Document: Decodable {
    let name: String
    let style: LevelStyleID
    let size: TileSize
    let player: TileCoordinate
    let portal: TileCoordinate
    let terrain: TerrainMap
    let background: BackgroundDescriptor
    let platforms: [PlatformDescriptor]
    let movingPlatforms: [MovingPlatformDescriptor]
    let ladders: [LadderDescriptor]
    let hazards: [HazardDescriptor]
    let enemies: [EnemyDescriptor]
    let pickups: [PickupDescriptor]
    let checkpoints: [CheckpointDescriptor]
    let decorations: [DecorationDescriptor]

    enum CodingKeys: String, CodingKey, CaseIterable {
        case format, name, style, size, player, portal, terrain, background
        case platforms, movingPlatforms, ladders, hazards
        case enemies, pickups, checkpoints, decorations
    }

    init(from decoder: Decoder) throws {
        // Версия — первой, ещё до строгой проверки ключей: у файла чужого
        // формата чужие и ключи, и жаловаться надо на версию, а не на них.
        let versioned = try decoder.container(keyedBy: CodingKeys.self)
        let format = try versioned.decode(Int.self, forKey: .format)
        guard format == LevelFile.formatVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .format, in: versioned,
                debugDescription: "версия формата \(format) не поддерживается, ожидается \(LevelFile.formatVersion)")
        }

        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)

        name = try c.decode(String.self, forKey: .name)
        style = LevelStyleID(try c.decode(String.self, forKey: .style))
        size = try c.decode(Pair.self, forKey: .size).size
        player = try c.decode(Pair.self, forKey: .player).point
        portal = try c.decode(Pair.self, forKey: .portal).point
        terrain = try Self.terrain(in: c)
        background = try c.decode(BackgroundRecord.self, forKey: .background).descriptor

        platforms = try c.list(PlatformRecord.self, forKey: .platforms).map(\.descriptor)
        movingPlatforms = try c.list(MovingPlatformRecord.self, forKey: .movingPlatforms).map(\.descriptor)
        ladders = try c.list(LadderRecord.self, forKey: .ladders).map(\.descriptor)
        hazards = try c.list(HazardRecord.self, forKey: .hazards).map(\.descriptor)
        enemies = try c.list(EnemyRecord.self, forKey: .enemies).map(\.descriptor)
        pickups = try c.list(PickupRecord.self, forKey: .pickups).map(\.descriptor)
        checkpoints = try c.list(CheckpointRecord.self, forKey: .checkpoints).map(\.descriptor)
        decorations = try c.list(DecorationRecord.self, forKey: .decorations).map(\.descriptor)
    }

    /// Рельеф — та же картинка, что в коде, только массивом строк: в JSON нет
    /// многострочных строк. Ошибка картинки указывает на её строку.
    private static func terrain(in c: KeyedDecodingContainer<CodingKeys>) throws -> TerrainMap {
        let rows = try c.decode([String].self, forKey: .terrain)
        do {
            return try TerrainMap(rows: rows)
        } catch {
            var path = c.codingPath + [CodingKeys.terrain]
            switch error {
            case .empty: break
            case let .raggedRow(row, _, _), let .unknownSymbol(_, row, _): path.append(AnyKey(index: row))
            }
            throw DecodingError.dataCorrupted(.init(codingPath: path, debugDescription: error.description))
        }
    }

    func configuration(sceneSize: CGSize) -> LevelConfiguration {
        LevelConfiguration(name: name,
                           style: style,
                           sceneSize: sceneSize,
                           levelWidthInTiles: size.width,
                           levelHeightInTiles: size.height,
                           playerStart: player,
                           terrain: terrain,
                           background: background,
                           platforms: platforms,
                           movingPlatforms: movingPlatforms,
                           ladders: ladders,
                           hazards: hazards,
                           enemies: enemies,
                           pickups: pickups,
                           checkpoints: checkpoints,
                           decorations: decorations,
                           portal: portal)
    }
}

// MARK: - Записи

/// Точка или размер: `[x, y]` / `[ширина, высота]`. Массив, а не объект
/// `{"x": …, "y": …}`: в списке из двадцати объектов объектная запись втрое
/// длиннее и читается хуже.
private struct Pair: Decodable {
    let first: CGFloat
    let second: CGFloat

    var point: TileCoordinate { TileCoordinate(x: first, y: second) }
    var size: TileSize { TileSize(width: first, height: second) }

    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        guard c.count == 2 else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "ожидается пара чисел [x, y]"))
        }
        first = try c.decode(CGFloat.self)
        second = try c.decode(CGFloat.self)
    }
}

private struct BackgroundRecord: Decodable {
    let descriptor: BackgroundDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case horizonLine, horizon, sky }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        descriptor = BackgroundDescriptor(
            fill: .solid,
            horizon: try c.decode(StripRecord<HorizonSegment>.self, forKey: .horizon).strip,
            sky: try c.decode(StripRecord<SkySegment>.self, forKey: .sky).strip,
            horizonLineInTiles: try c.decode(CGFloat.self, forKey: .horizonLine))
    }
}

private struct StripRecord<Segment: FileNamed & Equatable & Sendable>: Decodable {
    let strip: BackgroundStrip<Segment>

    enum CodingKeys: String, CodingKey, CaseIterable { case segments, width }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        strip = BackgroundStrip(segments: try c.decode([Named<Segment>].self, forKey: .segments).map(\.value),
                                widthInTiles: try c.decode(CGFloat.self, forKey: .width))
    }
}

private struct PlatformRecord: Decodable {
    let descriptor: PlatformDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case at, size }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        descriptor = PlatformDescriptor(rect: TileRect(origin: try c.decode(Pair.self, forKey: .at).point,
                                                       size: try c.decode(Pair.self, forKey: .size).size))
    }
}

private struct MovingPlatformRecord: Decodable {
    let descriptor: MovingPlatformDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case from, to, size, speed, stops }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        descriptor = MovingPlatformDescriptor(
            size: try c.decode(Pair.self, forKey: .size).size,
            start: try c.decode(Pair.self, forKey: .from).point,
            end: try c.decode(Pair.self, forKey: .to).point,
            speed: try c.decode(CGFloat.self, forKey: .speed),
            stops: try c.list(StopRecord.self, forKey: .stops).map(\.stop))
    }
}

private struct StopRecord: Decodable {
    let stop: MotionStop

    enum CodingKeys: String, CodingKey, CaseIterable { case progress, duration }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        stop = MotionStop(progress: try c.decode(CGFloat.self, forKey: .progress),
                          duration: try c.decode(TimeInterval.self, forKey: .duration))
    }
}

private struct LadderRecord: Decodable {
    let descriptor: LadderDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case at, height }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        descriptor = LadderDescriptor(origin: try c.decode(Pair.self, forKey: .at).point,
                                      height: try c.decode(CGFloat.self, forKey: .height))
    }
}

private struct HazardRecord: Decodable {
    let descriptor: HazardDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case kind, at, size }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        descriptor = HazardDescriptor(kind: try c.decode(Named<HazardKind>.self, forKey: .kind).value,
                                      rect: TileRect(origin: try c.decode(Pair.self, forKey: .at).point,
                                                     size: try c.decode(Pair.self, forKey: .size).size))
    }
}

private struct EnemyRecord: Decodable {
    let descriptor: EnemyDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case kind, at, patrol }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        descriptor = EnemyDescriptor(origin: try c.decode(Pair.self, forKey: .at).point,
                                     kind: try c.decode(Named<EnemyKind>.self, forKey: .kind).value,
                                     patrol: try c.decodeIfPresent(PatrolRecord.self, forKey: .patrol)?.patrol)
    }
}

private struct PatrolRecord: Decodable {
    let patrol: EnemyDescriptor.Patrol

    enum CodingKeys: String, CodingKey, CaseIterable { case leftX, rightX, speed }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        patrol = EnemyDescriptor.Patrol(leftX: try c.decode(CGFloat.self, forKey: .leftX),
                                        rightX: try c.decode(CGFloat.self, forKey: .rightX),
                                        speed: try c.decode(CGFloat.self, forKey: .speed))
    }
}

private struct PickupRecord: Decodable {
    let descriptor: PickupDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case kind, at }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        descriptor = PickupDescriptor(origin: try c.decode(Pair.self, forKey: .at).point,
                                      kind: try c.decode(Named<PickupDescriptor.Kind>.self, forKey: .kind).value)
    }
}

private struct CheckpointRecord: Decodable {
    let descriptor: CheckpointDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case at }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        descriptor = CheckpointDescriptor(origin: try c.decode(Pair.self, forKey: .at).point)
    }
}

private struct DecorationRecord: Decodable {
    let descriptor: DecorationDescriptor

    enum CodingKeys: String, CodingKey, CaseIterable { case id, at }

    init(from decoder: Decoder) throws {
        let c = try decoder.strictContainer(keyedBy: CodingKeys.self)
        // Идентификатор открытый: есть ли такая декорация у стиля, решает
        // `LevelValidation`, а не разбор — как и для уровня, описанного в коде.
        descriptor = DecorationDescriptor(id: DecorationID(try c.decode(String.self, forKey: .id)),
                                          origin: try c.decode(Pair.self, forKey: .at).point)
    }
}

// MARK: - Имена в файле

/// Закрытый `enum` модели, у которого есть имя в файле.
///
/// Имена заданы исчерпывающим `switch`, а не выведены из имён случаев: формат
/// файла — это договор, и переименование случая в Swift не должно молча
/// ломать все файлы уровней. Новый случай ломает сборку здесь — значит, его не
/// забудут сделать доступным файлам.
private protocol FileNamed {
    static var fileValues: [Self] { get }
    var fileName: String { get }
}

/// Значение закрытого `enum` по имени из файла. Незнакомое имя — ошибка со
/// списком допустимых: опечатку в файле видно сразу, без похода в код.
private struct Named<Value: FileNamed>: Decodable {
    let value: Value

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let name = try c.decode(String.self)
        guard let value = Value.fileValues.first(where: { $0.fileName == name }) else {
            let known = Value.fileValues.map(\.fileName).joined(separator: ", ")
            throw DecodingError.dataCorruptedError(in: c,
                                                   debugDescription: "незнакомое значение «\(name)», допустимы: \(known)")
        }
        self.value = value
    }
}

extension EnemyKind: FileNamed {
    fileprivate static var fileValues: [EnemyKind] { allCases }

    fileprivate var fileName: String {
        switch self {
        case .crab: return "crab"
        case .imp: return "imp"
        case .sniper: return "sniper"
        case .plant: return "plant"
        case .wasp: return "wasp"
        }
    }
}

extension HazardKind: FileNamed {
    fileprivate static var fileValues: [HazardKind] { allCases }

    fileprivate var fileName: String {
        switch self {
        case .water: return "water"
        case .lava: return "lava"
        }
    }
}

extension PickupDescriptor.Kind: FileNamed {
    fileprivate static var fileValues: [PickupDescriptor.Kind] {
        [.health] + CoinTier.allCases.map { .coin($0) }
    }

    /// Монета пишется с достоинством через точку — `"coin.gold"`, — как
    /// `.coin(.gold)` в коде.
    fileprivate var fileName: String {
        switch self {
        case .health:
            return "health"
        case .coin(let tier):
            switch tier {
            case .bronze: return "coin.bronze"
            case .silver: return "coin.silver"
            case .gold: return "coin.gold"
            }
        }
    }
}

extension HorizonSegment: FileNamed {
    fileprivate static var fileValues: [HorizonSegment] { allCases }

    fileprivate var fileName: String {
        switch self {
        case .hills: return "hills"
        case .mountains: return "mountains"
        case .interior: return "interior"
        case .fill: return "fill"
        }
    }
}

extension SkySegment: FileNamed {
    fileprivate static var fileValues: [SkySegment] { allCases }

    fileprivate var fileName: String {
        switch self {
        case .clouds: return "clouds"
        }
    }
}

// MARK: - Строгий разбор

/// Ключ без схемы: им читаются все ключи объекта, чтобы найти незнакомые, и
/// им же записывается номер строки рельефа в путь ошибки.
private struct AnyKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.init(index: intValue)
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
}

private extension Decoder {

    /// Объект, в котором нет ключей сверх `Key`. Незнакомый ключ — ошибка с
    /// путём до него: так опечатка в необязательном поле не исчезает молча.
    func strictContainer<Key: CodingKey & CaseIterable>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let raw = try container(keyedBy: AnyKey.self)
        let known = Set(Key.allCases.map(\.stringValue))
        // Порядок ключей в объекте не определён, а сообщение хочется
        // одинаковым от запуска к запуску.
        let unknown = raw.allKeys.map(\.stringValue).filter { !known.contains($0) }.sorted()
        if let first = unknown.first {
            let expected = Key.allCases.map(\.stringValue).joined(separator: ", ")
            throw DecodingError.dataCorrupted(.init(
                codingPath: codingPath + [AnyKey(stringValue: first)],
                debugDescription: "незнакомый ключ, допустимы: \(expected)"))
        }
        return try container(keyedBy: type)
    }
}

private extension KeyedDecodingContainer {

    /// Необязательный список: пропущенный ключ — пустой список.
    func list<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> [T] {
        try decodeIfPresent([T].self, forKey: key) ?? []
    }
}

// MARK: - Сообщения

private extension LevelFileError {

    init(_ error: DecodingError) {
        switch error {
        case let .keyNotFound(key, context):
            self.init(path: Self.path(context.codingPath + [key]), message: "обязательное поле отсутствует")
        case let .valueNotFound(type, context):
            self.init(path: Self.path(context.codingPath), message: "нет значения, ожидается \(Self.name(of: type))")
        case let .typeMismatch(type, context):
            self.init(path: Self.path(context.codingPath), message: "ожидается \(Self.name(of: type))")
        case let .dataCorrupted(context):
            // Пустой путь — значит, файл не разобран как JSON5 вовсе;
            // подробности (строка, символ) лежат в исходной ошибке.
            if context.codingPath.isEmpty, let underlying = context.underlyingError as NSError? {
                let details = underlying.userInfo[NSDebugDescriptionErrorKey] as? String ?? underlying.localizedDescription
                self.init(path: "", message: "не читается как JSON5: \(details)")
            } else {
                self.init(path: Self.path(context.codingPath), message: context.debugDescription)
            }
        @unknown default:
            self.init(path: "", message: String(describing: error))
        }
    }

    /// Путь в записи файла: `enemies[1].patrol.speed`.
    static func path(_ keys: [CodingKey]) -> String {
        keys.reduce(into: "") { path, key in
            if let index = key.intValue {
                path += "[\(index)]"
            } else {
                path += path.isEmpty ? key.stringValue : ".\(key.stringValue)"
            }
        }
    }

    static func name(of type: Any.Type) -> String {
        switch type {
        case is String.Type: return "строка"
        case is Int.Type: return "целое число"
        case is Double.Type, is CGFloat.Type: return "число"
        default:
            let name = String(describing: type)
            return name.hasPrefix("Array") || name.hasPrefix("[") ? "список" : name
        }
    }
}
