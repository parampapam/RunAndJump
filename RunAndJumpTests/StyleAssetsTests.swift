//
//  StyleAssetsTests.swift
//  RunAndJumpTests
//

import Testing
import CoreGraphics
import SpriteKit
import UIKit
@testable import RunAndJump

/// Единственный набор тестов, которому нужен SpriteKit.
///
/// Это осознанное исключение из конвенции «тесты покрывают только модель».
/// Каталог стиля называет текстуры **строками**, и компилятор их больше не
/// проверяет — а проверить надо: опечатка в имени даёт не ошибку сборки, а
/// розовый квадрат в игре. Сверить имя с настоящим атласом можно только
/// спросив сам атлас, то есть через SpriteKit.
///
/// Исключение записано в CLAUDE.md — иначе следующая уборка удалит этот файл
/// как не соответствующий конвенции.
@Suite("Каталоги стилей против настоящих ассетов")
struct StyleAssetsTests {

    @Test("Каждое имя ландшафта и декорации есть в атласах своего стиля")
    @MainActor
    func everyCatalogNameExistsInItsAtlases() {
        for catalog in StyleCatalogs.all {
            let textures = LevelTextures(catalog: catalog)

            for (role, name) in terrainNames(of: catalog) {
                #expect(textures.knowsTexture(named: name),
                        "\(catalog.id.rawValue).\(role): нет текстуры «\(name)»")
            }

            for (id, entry) in catalog.decorations {
                for frame in entry.tiles.flatMap(\.frames) {
                    #expect(textures.knowsTexture(named: frame),
                            "\(catalog.id.rawValue)/\(id.rawValue): нет текстуры «\(frame)»")
                }
            }
        }
    }

    @Test("Каждый слой фона есть среди картинок проекта")
    @MainActor
    func everyBackgroundLayerExists() {
        for catalog in StyleCatalogs.all {
            let background = catalog.background
            for name in [background.fill, background.hills, background.mountains, background.clouds] {
                // Слои фона — отдельные Image Set, а не кадры атласа, поэтому
                // спрашиваем их у каталога ассетов напрямую.
                #expect(UIImage(named: name) != nil,
                        "\(catalog.id.rawValue): нет картинки «\(name)»")
            }
        }
    }

    @Test("Цвет неба совпадает с заливкой фона")
    @MainActor
    func skyColorMatchesTheBackgroundFill() throws {
        for catalog in StyleCatalogs.all {
            let image = try #require(UIImage(named: catalog.background.fill),
                                     "\(catalog.id.rawValue): нет заливки фона")
            let pixel = try #require(image.cgImage.map(averageColor(of:)),
                                     "\(catalog.id.rawValue): заливка без растра")

            // Допуск в один уровень 8-битного канала: заливка — сплошной цвет,
            // но проходит через кодирование PNG и цветовое пространство.
            let tolerance = 1.0 / 255
            #expect(abs(pixel.red - catalog.skyColor.red) <= tolerance)
            #expect(abs(pixel.green - catalog.skyColor.green) <= tolerance)
            #expect(abs(pixel.blue - catalog.skyColor.blue) <= tolerance)
        }
    }

    // MARK: - Вспомогательное

    private func terrainNames(of catalog: StyleCatalog) -> [(String, String)] {
        let terrain = catalog.terrain
        return [
            ("groundTop", terrain.groundTop),
            ("platformLeft", terrain.platformLeft),
            ("platformMiddle", terrain.platformMiddle),
            ("platformRight", terrain.platformRight),
            ("ladderBottom", terrain.ladderBottom),
            ("ladderMiddle", terrain.ladderMiddle),
            ("ladderTop", terrain.ladderTop),
            ("ladderTop75", terrain.ladderTop75),
            ("ladderTop50", terrain.ladderTop50),
            ("ladderTop25", terrain.ladderTop25),
        ]
    }

    /// Средний цвет картинки. Заливка одноцветна, поэтому среднее — это и есть
    /// её цвет, а усреднение избавляет от вопроса «какой пиксель брать».
    private func averageColor(of image: CGImage) -> RGBColor {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        pixels.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress,
                  let context = CGContext(
                      data: base,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: width * 4,
                      space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else { return }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        var totals = (red: 0, green: 0, blue: 0)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            totals.red += Int(pixels[index])
            totals.green += Int(pixels[index + 1])
            totals.blue += Int(pixels[index + 2])
        }

        let count = Double(width * height) * 255
        return RGBColor(red: Double(totals.red) / count,
                        green: Double(totals.green) / count,
                        blue: Double(totals.blue) / count)
    }
}
