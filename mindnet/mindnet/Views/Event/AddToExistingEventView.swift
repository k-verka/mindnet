//
//  AddToExistingEventView.swift
//  mindnet
//
//  Created by wv on 29/11/2025.
//


import SwiftUI
import SwiftData

struct AddToExistingEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allEvents: [ModelEvent]
    
    let user: ModelUser
    @State private var searchText = ""
    
    // Получаем текущего пользователя (организатора)
    @State private var currentUser: ModelUser?
    
    var availableEvents: [ModelEvent] {
        allEvents.filter { event in
            // Показываем только события где:
            // 1. Пользователь еще не участник
            // 2. Я являюсь организатором (могу добавлять людей)
            !event.participants.contains(where: { $0.id == user.id }) &&
            currentUser != nil &&
            event.isCreator(currentUser!) &&
            (searchText.isEmpty || event.title.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableEvents) { event in
                    Button(action: {
                        addUserToEvent(event)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(event.eventDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 8) {
                                    Label("\(event.participants.count)", systemImage: "person.2.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Вы - Организатор")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Поиск события")
            .navigationTitle("Добавить в событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .overlay {
                if availableEvents.isEmpty {
                    ContentUnavailableView(
                        "Нет доступных событий",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Создайте событие где вы организатор, чтобы добавлять участников")
                    )
                }
            }
            .onAppear {
                currentUser = getOrCreateCurrentUser()
            }
        }
    }
    
    private func addUserToEvent(_ event: ModelEvent) {
        // Добавляем пользователя в участники
        event.participants.append(user)
        user.events.append(event)
        
        // Назначаем роль "participant"
        event.participantRoles[user.id] = "participant"
        
        event.updatedAt = Date()
        
        try? context.save()
        dismiss()
    }
    
    private func getOrCreateCurrentUser() -> ModelUser? {
        let fetchDescriptor = FetchDescriptor<ModelUser>(
            predicate: #Predicate { $0.name == "Я" }
        )
        
        if let existingUser = try? context.fetch(fetchDescriptor).first {
            return existingUser
        }
        
        let newUser = ModelUser(name: "Я")
        context.insert(newUser)
        return newUser
    }
}
