//
//  LevelTextures.swift
//  RunAndJump
//

import SpriteKit

/// Тема уровня: каталог стиля плюс атласы, в которых лежат его картинки.
/// SpriteKit здесь есть, узла — нет: это слой ресурсов, единственная работа
/// которого — превратить имя из каталога в `SKTexture`.
///
/// Ради этого типа всё и затевалось. Раньше атласы лежали в `static let` прямо
/// в узлах (`LevelBuilder`, `Ladder`, `PlatformSkin`), и подменить их снаружи
/// было нельзя: скрытое глобальное состояние, из-за которого второй стиль был
/// невозможен в принципе. Теперь тему создаёт сцена по `LevelConfiguration.style`
/// и раздаёт вниз — узлы получают текстуры параметром и про стиль не знают.
///
/// `@MainActor` — потому что `SKTextureAtlas` не `Sendable`, а тема живёт ровно
/// там же, где сцена.
@MainActor
struct LevelTextures {

    let catalog: StyleCatalog

    /// Атласы стиля в порядке поиска и указатель «имя → атлас, где оно лежит».
    /// Указатель строится один раз: искать перебором по атласам на каждую
    /// плитку земли — это работа на каждый кадр сборки уровня.
    private let atlases: [SKTextureAtlas]
    private let atlasByName: [String: SKTextureAtlas]

    init(catalog: StyleCatalog) {
        self.catalog = catalog

        let atlases = catalog.atlases.map { SKTextureAtlas(named: $0) }
        var index: [String: SKTextureAtlas] = [:]
        for atlas in atlases {
            // Первый атлас в списке главнее: порядок в каталоге — это и есть
            // порядок поиска имени.
            for name in atlas.textureNames where index[name] == nil {
                index[name] = atlas
            }
        }

        self.atlases = atlases
        self.atlasByName = index
    }

    // MARK: - Разрешение имён

    /// Есть ли такая картинка в атласах стиля. Нужна валидации (`LevelValidation`):
    /// открытые имена компилятор не проверяет, проверяет тест.
    func knowsTexture(named name: String) -> Bool {
        atlasByName[name] != nil
    }

    /// Текстура по имени из каталога.
    ///
    /// Чего нет в атласах, ищется среди Image Set — так грузятся слои фона:
    /// каждый из них отдельная картинка со своим `zPosition`, паковать их в
    /// атлас незачем.
    func texture(named name: String) -> SKTexture {
        guard let atlas = atlasByName[name] else { return SKTexture(imageNamed: name) }
        return atlas.textureNamed(name)
    }

    // MARK: - Роли ландшафта

    func groundTop() -> SKTexture {
        texture(named: catalog.terrain.groundTop)
    }

    func platform(_ part: PlatformTiling.Part) -> SKTexture {
        texture(named: catalog.terrain.name(for: part))
    }

    func ladder(_ part: LadderTiling.Part) -> SKTexture {
        texture(named: catalog.terrain.name(for: part))
    }

    // MARK: - Декорации

    /// Запись каталога; `nil` — такой декорации у стиля нет.
    func decoration(_ id: DecorationID) -> DecorationEntry? {
        catalog.decorations[id]
    }

    // MARK: - Фон

    func background(_ fill: BackgroundFill) -> SKTexture {
        texture(named: catalog.background.name(for: fill))
    }

    /// `nil` — сегмент ничего не рисует, и на его месте видна заливка.
    func background(_ segment: HorizonSegment) -> SKTexture? {
        guard let name = catalog.background.name(for: segment) else { return nil }
        return texture(named: name)
    }

    func background(_ segment: SkySegment) -> SKTexture {
        texture(named: catalog.background.name(for: segment))
    }

    /// Цвет фона сцены. Виден на дне ям под озёрами — там, где за жидкостью
    /// нет грунта, и совпадает с заливкой фона (см. `StyleCatalog.skyColor`).
    var skyColor: SKColor {
        SKColor(red: CGFloat(catalog.skyColor.red),
                green: CGFloat(catalog.skyColor.green),
                blue: CGFloat(catalog.skyColor.blue),
                alpha: 1)
    }
}
