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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ModelUser.self,
            ModelMessage.self,
            ModelEvent.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Создаём mock данные при первом запуске
            #if DEBUG
            let context = ModelContext(container)
            MockDataManager.createMockData(context: context)
            #endif
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
