import SwiftUI
import SpriteKit

struct ContentView: View {

    // Сцена живёт в @StateObject, а не в вычисляемом свойстве: иначе каждый
    // пересчёт body создавал бы её заново и игра молча возвращалась бы в главное
    // меню посреди партии. Подробности — в GameHost.
    @StateObject private var game: GameHost

    init(store: any GameProgressStore = UserDefaultsProgressStore()) {
        // wrappedValue у StateObject — автозамыкание: хост и сцена создаются
        // при первом показе экрана и переживают все последующие пересчёты body.
        _game = StateObject(wrappedValue: GameHost(store: store))
    }

    var body: some View {
        SpriteView(
            scene: game.scene,
            debugOptions: [.showsPhysics, .showsFPS, .showsNodeCount]
        )
        .ignoresSafeArea()
    }
}

#Preview {
    // Превью не трогает сохранение настоящей игры.
    ContentView(store: NullProgressStore())
}
