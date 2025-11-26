//
//  mindnetApp.swift
//  mindnet
//
//  Created by wv on 24/11/2025.
//

import SwiftUI
import SwiftData

@main
struct mindnetApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            ModelUser.self,
            ModelMessage.self,
            ModelEvent.self
        ])
    }
}
