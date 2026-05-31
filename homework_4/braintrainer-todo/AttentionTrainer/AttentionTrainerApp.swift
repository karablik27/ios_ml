//
//  AttentionTrainerApp.swift
//  AttentionTrainer
//
//  Created by B.RF Group on 10.04.2026.
//

import SwiftUI

@main
struct AttentionTrainerApp: App {
    @StateObject private var userStats = UserStats()
    
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(userStats)
        }
    }
}
