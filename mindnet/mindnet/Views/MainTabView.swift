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

struct EventListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ModelEvent.eventDate, order: .reverse) private var events: [ModelEvent]
    @State private var showingAddEvent = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        EventRowView(event: event)
                    }
                }
            }
            .navigationTitle("События")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView()
            }
            .overlay {
                if events.isEmpty {
                    ContentUnavailableView(
                        "Нет событий",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Создайте первое событие или добавьте через контакт")
                    )
                }
            }
        }
    }
}

struct EventRowView: View {
    let event: ModelEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка события
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                Image(systemName: "calendar")
                    .foregroundStyle(.purple)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                Text(event.eventDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    // Участники
                    Label("\(event.participants.count)", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Комментарии
                    Label("\(event.comments.count)", systemImage: "message.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Фото
                    if !event.photoPaths.isEmpty {
                        Label("\(event.photoPaths.count)", systemImage: "photo.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Настройки") {
                    Label("Уведомления", systemImage: "bell.fill")
                    Label("О приложении", systemImage: "info.circle.fill")
                }
            }
            .navigationTitle("Профиль")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ModelUser.self, ModelMessage.self, ModelEvent.self])
}
