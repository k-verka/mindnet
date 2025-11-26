//
//  ContentView.swift
//  mindnet
//
//  Created by wv on 24/11/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ModelUser.name) private var users: [ModelUser]
    @State private var showingAddUser = false
    @State private var searchText = ""
    
    var filteredUsers: [ModelUser] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.profession?.localizedCaseInsensitiveContains(searchText) == true ||
            user.city?.localizedCaseInsensitiveContains(searchText) == true ||
            user.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredUsers) { user in
                    NavigationLink(destination: UserDetailView(user: user)) {
                        UserRowView(user: user)
                    }
                }
                .onDelete(perform: deleteUsers)
            }
            .searchable(text: $searchText, prompt: "Поиск по имени, профессии, городу...")
            .navigationTitle("Контакты")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddUser = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView()
            }
            .overlay {
                if users.isEmpty {
                    ContentUnavailableView(
                        "Нет контактов",
                        systemImage: "person.3",
                        description: Text("Добавьте первый контакт, нажав +")
                    )
                }
            }
        }
    }
    
    private func deleteUsers(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredUsers[index])
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [ModelUser.self, ModelNote.self])
}

// Если нужен preview с тестовыми данными:
#Preview("С данными") {
    let container = try! ModelContainer(
        for: ModelUser.self,
        ModelNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    // Создаем тестовых пользователей
    let user1 = ModelUser(
        name: "wv",
        birthdate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
        city: "Amsterdam",
        profession: "iOS Developer",
        skills: ["Swift", "SwiftUI", "Python"],
        tags: ["Друзья", "Разработка"]
    )
    
    let user2 = ModelUser(
        name: "Иван Петров",
        birthdate: Date(),
        city: "Москва",
        profession: "Designer",
        skills: ["Figma", "Sketch"],
        tags: ["Коллеги", "Дизайн"]
    )
    
    container.mainContext.insert(user1)
    container.mainContext.insert(user2)
    
    return ContentView()
        .modelContainer(container)
}
