//
//  BackgroundLayoutTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 15.08.2026.
//

import Testing
import CoreGraphics
@testable import RunAndJump

struct BackgroundLayoutTests {

    // Размеры взяты близкими к настоящим: уровень 45 × 16 тайлов, видимая
    // область 10 тайлов в высоту (`WorldMetrics.visibleTilesTall`) и ~17.8 в
    // ширину при пропорции экрана.
    private let level = TileSize(width: 45, height: 16)
    private let viewport = TileSize(width: 18, height: 10)

    private let background = BackgroundDescriptor(
        fill: .daySky,
        horizon: BackgroundStrip(segments: [.hills, .fill, .mountains], widthInTiles: 8),
        sky: BackgroundStrip(segments: [.clouds], widthInTiles: 12),
        horizonLineInTiles: 5
    )

    /// Камера в крайнем левом-нижнем положении: центр на половине видимой области.
    private var cameraAtStart: CGPoint {
        CGPoint(x: viewport.width / 2, y: viewport.height / 2)
    }

    /// Камера в крайнем правом-верхнем положении.
    private var cameraAtEnd: CGPoint {
        CGPoint(x: level.width - viewport.width / 2, y: level.height - viewport.height / 2)
    }

    private func horizon(camera: CGPoint) -> BackgroundLayout.Strip {
        BackgroundLayout.horizon(background,
                                 levelSizeInTiles: level,
                                 viewportSizeInTiles: viewport,
                                 cameraCenterInTiles: camera)
    }

    private func sky(camera: CGPoint) -> BackgroundLayout.Strip {
        BackgroundLayout.sky(background,
                             levelSizeInTiles: level,
                             viewportSizeInTiles: viewport,
                             cameraCenterInTiles: camera)
    }

    // MARK: - Смещение полосы

    @Test("В начале уровня полоса стоит в его нижнем-левом углу")
    func stripStartsAtLevelOrigin() {
        let strip = horizon(camera: cameraAtStart)
        #expect(strip.origin.x == 0)
        #expect(strip.origin.y == 0)
    }

    @Test("Полоса отстаёт от камеры на долю параллакса")
    func stripLagsBehindCamera() {
        let strip = horizon(camera: CGPoint(x: cameraAtStart.x + 10, y: cameraAtStart.y))
        // Камера сдвинулась на 10 тайлов, полоса — на 10 × (1 − 0.35).
        #expect(abs(strip.origin.x - 10 * (1 - BackgroundParallax.horizon)) < 0.0001)
    }

    @Test("Верхняя полоса едет по экрану медленнее нижней")
    func skyDriftsSlowerThanHorizon() {
        // «Скорость» полосы видна не в её координате в уровне, а в том, на
        // сколько она уползла по экрану, пока камера прошла те же 10 тайлов.
        func screenDrift(_ strip: (CGPoint) -> BackgroundLayout.Strip) -> CGFloat {
            let moved = CGPoint(x: cameraAtStart.x + 10, y: cameraAtStart.y)
            let before = strip(cameraAtStart).origin.x - (cameraAtStart.x - viewport.width / 2)
            let after = strip(moved).origin.x - (moved.x - viewport.width / 2)
            return abs(after - before)
        }

        #expect(screenDrift(sky(camera:)) < screenDrift(horizon(camera:)))
    }

    @Test("За краями уровня полоса дальше не едет")
    func cameraBeyondLevelDoesNotMoveStrip() {
        let atEnd = horizon(camera: cameraAtEnd)
        let beyondEnd = horizon(camera: CGPoint(x: cameraAtEnd.x + 100, y: cameraAtEnd.y))
        #expect(atEnd.origin == beyondEnd.origin)
    }

    // MARK: - Охват

    @Test("Содержимого хватает, чтобы покрыть экран в конце уровня")
    func contentCoversViewportAtLevelEnd() throws {
        let strip = horizon(camera: cameraAtEnd)
        let last = try #require(strip.placements.last)
        let contentRight = strip.origin.x + last.rect.origin.x + last.rect.size.width
        let viewportRight = level.width
        #expect(contentRight >= viewportRight)
    }

    @Test("Содержимого хватает и в середине уровня")
    func contentCoversViewportInTheMiddle() throws {
        let camera = CGPoint(x: level.width / 2, y: cameraAtStart.y)
        let strip = horizon(camera: camera)
        let last = try #require(strip.placements.last)
        let contentRight = strip.origin.x + last.rect.origin.x + last.rect.size.width
        #expect(contentRight >= camera.x + viewport.width / 2)
    }

    @Test("Полоса короче уровня: параллакс сжимает её мир")
    func contentIsShorterThanLevel() throws {
        let last = try #require(horizon(camera: cameraAtStart).placements.last)
        let contentWidth = last.rect.origin.x + last.rect.size.width
        #expect(contentWidth < level.width)
        #expect(contentWidth >= viewport.width)
    }

    // MARK: - Сегменты

    @Test("Сегменты идут встык, без зазоров и нахлёстов")
    func segmentsAreAdjacent() {
        let placements = horizon(camera: cameraAtStart).placements
        for (previous, next) in zip(placements, placements.dropFirst()) {
            #expect(previous.rect.origin.x + previous.rect.size.width == next.rect.origin.x)
        }
    }

    @Test("Узор повторяется с начала, когда список кончился")
    func segmentsCycle() {
        let placements = horizon(camera: cameraAtStart).placements
        #expect(placements.count > background.horizon.segments.count)
        for (index, placement) in placements.enumerated() {
            #expect(placement.segmentIndex == index % background.horizon.segments.count)
        }
    }

    @Test("Пустая полоса не даёт ни одного сегмента")
    func emptyStripHasNoPlacements() {
        let empty = BackgroundDescriptor(
            fill: .daySky,
            horizon: BackgroundStrip(segments: [], widthInTiles: 8),
            sky: BackgroundStrip(segments: [.clouds], widthInTiles: 12),
            horizonLineInTiles: 5
        )
        let strip = BackgroundLayout.horizon(empty,
                                             levelSizeInTiles: level,
                                             viewportSizeInTiles: viewport,
                                             cameraCenterInTiles: cameraAtStart)
        #expect(strip.placements.isEmpty)
    }

    // MARK: - Стык полос

    @Test("Верх нижней полосы всегда совпадает с низом верхней",
          arguments: [0.0, 3.0, 6.0] as [CGFloat])
    func stripsMeetAtHorizonLine(cameraHeight: CGFloat) throws {
        let camera = CGPoint(x: cameraAtStart.x, y: cameraAtStart.y + cameraHeight)
        let bottom = horizon(camera: camera)
        let top = sky(camera: camera)

        let bottomPlacement = try #require(bottom.placements.first)
        let horizonTop = bottom.origin.y + bottomPlacement.rect.size.height
        #expect(abs(horizonTop - top.origin.y) < 0.0001)
    }

    @Test("Верхняя полоса достаёт до верха экрана в самом высоком положении камеры")
    func skyCoversTopOfViewport() throws {
        let camera = CGPoint(x: cameraAtStart.x, y: cameraAtEnd.y)
        let strip = sky(camera: camera)
        let placement = try #require(strip.placements.first)
        let stripTop = strip.origin.y + placement.rect.size.height
        #expect(stripTop >= camera.y + viewport.height / 2)
    }

    @Test("Нижняя полоса не поднимается над низом экрана")
    func horizonStaysBelowViewportBottom() {
        for cameraHeight in stride(from: 0.0, through: 6.0, by: 2.0) {
            let camera = CGPoint(x: cameraAtStart.x, y: cameraAtStart.y + cameraHeight)
            let strip = horizon(camera: camera)
            #expect(strip.origin.y <= camera.y - viewport.height / 2)
        }
    }
}
