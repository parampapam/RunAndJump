//
//  BackgroundLayout.swift
//  RunAndJump
//
//  Created by Roman Pospelov on 15.08.2026.
//

import CoreGraphics

/// Раскладка фона: где лежит каждая полоса при текущем положении камеры и из
/// каких сегментов она собрана. Чистая геометрия в тайлах — узел только ставит
/// спрайты по готовым прямоугольникам.
///
/// ## Как считается охват
///
/// Полоса едет медленнее камеры, поэтому её содержимое **короче уровня**.
/// Пусть `V` — видимая ширина, `P` — ход камеры (`ширина уровня − V`),
/// `f` — коэффициент параллакса. Тогда:
///
///     левый край полосы  = левый край видимой области × (1 − f)
///     длина содержимого  = V + f × P
///
/// При `f = 0` полоса длиной ровно в экран и не двигается относительно него,
/// при `f = 1` — длиной в уровень и стоит в мире. Между ними левый край полосы
/// доезжает до нужного места ровно к моменту, когда камера упирается в правый
/// край уровня, поэтому пустоты по краям не бывает и запаса не нужно.
enum BackgroundLayout {

    /// Место одного сегмента внутри полосы.
    struct Placement: Equatable {
        /// Индекс в списке сегментов полосы. Список зациклен, поэтому индекс
        /// уже приведён по остатку — узлу считать нечего.
        let segmentIndex: Int
        /// Прямоугольник в системе координат полосы (относительно её
        /// `origin`), в тайлах, привязка — нижний-левый угол.
        let rect: TileRect
    }

    /// Готовая к отрисовке полоса.
    struct Strip: Equatable {
        /// Нижний-левый угол полосы в координатах **уровня**, в тайлах.
        let origin: CGPoint
        let placements: [Placement]
    }

    /// Нижняя полоса: от низа уровня до линии горизонта.
    static func horizon(_ background: BackgroundDescriptor,
                        levelSizeInTiles level: TileSize,
                        viewportSizeInTiles viewport: TileSize,
                        cameraCenterInTiles camera: CGPoint) -> Strip {
        strip(segmentCount: background.horizon.segments.count,
              segmentWidthInTiles: background.horizon.widthInTiles,
              bottomInTiles: 0,
              heightInTiles: background.horizonLineInTiles,
              level: level,
              viewport: viewport,
              camera: camera,
              horizontalFactor: BackgroundParallax.horizon)
    }

    /// Верхняя полоса: от линии горизонта до верха видимой области.
    ///
    /// Высота не задаётся уровнем, а выводится: полоса обязана дотянуться до
    /// верха экрана в самом высоком положении камеры, и это ровно один
    /// расчёт — авторам уровней подбирать его вручную незачем.
    static func sky(_ background: BackgroundDescriptor,
                    levelSizeInTiles level: TileSize,
                    viewportSizeInTiles viewport: TileSize,
                    cameraCenterInTiles camera: CGPoint) -> Strip {
        let visibleHeight = min(viewport.height, level.height)
        let cameraTravel = max(0, level.height - visibleHeight)
        // Низ полосы едет вверх медленнее камеры (на долю `1 − f`), поэтому с
        // подъёмом камеры непокрытый кусок сверху растёт — берём худший случай.
        let height = max(0, visibleHeight - background.horizonLineInTiles
                            + cameraTravel * BackgroundParallax.vertical)

        return strip(segmentCount: background.sky.segments.count,
                     segmentWidthInTiles: background.sky.widthInTiles,
                     bottomInTiles: background.horizonLineInTiles,
                     heightInTiles: height,
                     level: level,
                     viewport: viewport,
                     camera: camera,
                     horizontalFactor: BackgroundParallax.sky)
    }

    // MARK: - Общий расчёт

    private static func strip(segmentCount: Int,
                              segmentWidthInTiles segmentWidth: CGFloat,
                              bottomInTiles bottom: CGFloat,
                              heightInTiles height: CGFloat,
                              level: TileSize,
                              viewport: TileSize,
                              camera: CGPoint,
                              horizontalFactor: CGFloat) -> Strip {
        let origin = CGPoint(
            x: originOffset(levelExtent: level.width,
                            visibleExtent: viewport.width,
                            cameraCenter: camera.x,
                            factor: horizontalFactor),
            y: originOffset(levelExtent: level.height,
                            visibleExtent: viewport.height,
                            cameraCenter: camera.y,
                            factor: BackgroundParallax.vertical) + bottom
        )

        return Strip(origin: origin,
                     placements: placements(segmentCount: segmentCount,
                                            segmentWidth: segmentWidth,
                                            contentWidth: contentExtent(levelExtent: level.width,
                                                                        visibleExtent: viewport.width,
                                                                        factor: horizontalFactor),
                                            height: height))
    }

    /// Смещение полосы по одной оси: край видимой области, умноженный на
    /// «отставание» полосы от камеры.
    private static func originOffset(levelExtent: CGFloat,
                                     visibleExtent: CGFloat,
                                     cameraCenter: CGFloat,
                                     factor: CGFloat) -> CGFloat {
        let visible = min(visibleExtent, levelExtent)
        let travel = max(0, levelExtent - visible)
        // Камеру клэмпит `CameraMath`, но полоса не должна зависеть от того,
        // вызвали его до неё или нет: за краями уровня фона всё равно нет.
        let cameraEdge = min(max(cameraCenter - visible / 2, 0), travel)
        return cameraEdge * (1 - factor)
    }

    /// Длина содержимого полосы по одной оси.
    private static func contentExtent(levelExtent: CGFloat,
                                      visibleExtent: CGFloat,
                                      factor: CGFloat) -> CGFloat {
        let visible = min(visibleExtent, levelExtent)
        return visible + max(0, levelExtent - visible) * factor
    }

    private static func placements(segmentCount: Int,
                                   segmentWidth: CGFloat,
                                   contentWidth: CGFloat,
                                   height: CGFloat) -> [Placement] {
        guard segmentCount > 0, segmentWidth > 0, contentWidth > 0, height > 0 else { return [] }

        let count = Int((contentWidth / segmentWidth).rounded(.up))
        return (0..<count).map { index in
            Placement(
                segmentIndex: index % segmentCount,
                rect: TileRect(origin: TileCoordinate(x: CGFloat(index) * segmentWidth, y: 0),
                               size: TileSize(width: segmentWidth, height: height))
            )
        }
    }
}
