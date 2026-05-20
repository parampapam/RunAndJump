import SwiftUI
import SpriteKit

struct ContentView: View {
    @MainActor
    var scene: SKScene {
        let firstLevel = Levels.all[0]
        let scene = GameScene(configuration: firstLevel, progress: .initial)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(
            scene: scene,
            debugOptions: [.showsPhysics, .showsFPS, .showsNodeCount]
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
