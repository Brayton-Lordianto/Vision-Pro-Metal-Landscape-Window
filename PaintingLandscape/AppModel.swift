//
//  AppModel.swift
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 7/6/25.
//

import SwiftUI
import simd

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    var lookDir = vector_float3(0.0, 2.0, -90.0)
}
