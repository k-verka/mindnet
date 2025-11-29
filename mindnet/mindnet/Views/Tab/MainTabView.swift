//
//  MainTabView.swift
//  mindnet
//
//  Created by wv on 26/11/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            // Вкладка Контакты
            ContentView()
                .tabItem {
                    Label("Контакты", systemImage: "person.2.fill")
                }
            
            // Вкладка События
            EventListView()
                .tabItem {
                    Label("События", systemImage: "calendar.badge.clock")
                }
            
            // Вкладка Профиль (опционально, можно добавить позже)
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.circle.fill")
                }   
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ModelUser.self, ModelMessage.self, ModelEvent.self])
}
