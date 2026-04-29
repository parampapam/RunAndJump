import SwiftUI
import SpriteKit

struct ContentView: View {
    var scene: SKScene {
        let scene = GameScene(size: CGSize(width: 750, height: 1334))
        scene.scaleMode = .aspectFill
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
