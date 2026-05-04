import SwiftUI
import SpriteKit

struct ContentView: View {
    var scene: SKScene {
        let scene = GameScene(size: CGSize(width: 1334, height: 750))
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
