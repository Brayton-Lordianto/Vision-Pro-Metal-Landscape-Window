//
//  ContentView.swift
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 7/6/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
 
    var body: some View {
        VStack {

            VStack(spacing: 20) {
                Text("Look Direction Controls")
                    .font(.headline)
                
                @Bindable var bindableAppModel = appModel
                
                VStack {
                    Text("X: \(appModel.lookDir.x, specifier: "%.1f")")
                    Slider(value: $bindableAppModel.lookDir.x, in: -100...100, step: 1)
                }
                
                VStack {
                    Text("Y: \(appModel.lookDir.y, specifier: "%.1f")")
                    Slider(value: $bindableAppModel.lookDir.y, in: -100...100, step: 1)
                }
                
                VStack {
                    Text("Z: \(appModel.lookDir.z, specifier: "%.1f")")
                    Slider(value: $bindableAppModel.lookDir.z, in: -100...100, step: 1)
                }
            }
            .padding()

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
