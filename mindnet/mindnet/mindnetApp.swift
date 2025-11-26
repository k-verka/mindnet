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
            ContentView()
        }
        .modelContainer(for: [
            ModelUser.self,
            ModelNote.self
        ])
    }
}
