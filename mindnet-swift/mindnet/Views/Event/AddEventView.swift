//
//  AddEventView.swift
//  mindnet
//
//  Created by wv on 26/11/2025.
//

import SwiftUI
import SwiftData

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allUsers: [ModelUser]
    
    // Предзаполненный участник (если создаём из контакта)
    let preselectedUser: ModelUser?
    
    @State private var title = ""
    @State private var eventDate = Date()
    @State private var eventDescription = ""
    @State private var selectedParticipants: Set<ModelUser> = []
    @State private var showingUserPicker = false
    
    // Для создания "себя" как организатора
    @State private var currentUser: ModelUser?
    
    init(preselectedUser: ModelUser? = nil) {
        self.preselectedUser = preselectedUser
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Информация о событии") {
                    TextField("Название", text: $title)
                    
                    DatePicker("Дата", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "ru_RU"))
                    
                    TextField("Описание (опционально)", text: $eventDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Участники") {
                    // Показываем предзаполненного участника
                    if let preselected = preselectedUser {
                        HStack {
                            UserAvatarView(user: preselected, size: 32)
                            VStack(alignment: .leading) {
                                Text(preselected.name)
                                    .font(.subheadline)
                                Text("Участник")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    // Выбранные участники
                    ForEach(Array(selectedParticipants)) { user in
                        HStack {
                            UserAvatarView(user: user, size: 32)
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.subheadline)
                                Text("Участник")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(action: { selectedParticipants.remove(user) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    Button(action: { showingUserPicker = true }) {
                        Label("Добавить участника", systemImage: "plus.circle.fill")
                    }
                }
                
                Section {
                    Text("Вы станете организатором события и сможете управлять участниками и настройками.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Новое событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        createEvent()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingUserPicker) {
                UserPickerView(selectedUsers: $selectedParticipants, excludeUser: preselectedUser)
            }
            .onAppear {
                // Если есть предзаполненный участник, добавляем его
                if let preselected = preselectedUser {
                    selectedParticipants.insert(preselected)
                }
                
                // Создаём "себя" если нет (для MVP - просто фиктивный пользователь)
                if currentUser == nil {
                    currentUser = getOrCreateCurrentUser()
                }
            }
        }
    }
    
    private func createEvent() {
        guard let creator = currentUser else { return }
        
        var participants = Array(selectedParticipants)
        
        // Добавляем создателя в участники если его там нет
        if !participants.contains(where: { $0.id == creator.id }) {
            participants.append(creator)
        }
        
        // Создаём словарь ролей
        var roles: [UUID: String] = [:]
        roles[creator.id] = "creator"  // Создатель - организатор
        
        for participant in participants where participant.id != creator.id {
            roles[participant.id] = "participant"  // Остальные - участники
        }
        
        let event = ModelEvent(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            eventDate: eventDate,
            eventDescription: eventDescription.isEmpty ? nil : eventDescription,
            creator: creator,
            participants: participants,
            participantRoles: roles
        )
        
        context.insert(event)
        
        // Добавляем событие в список событий участников
        for participant in participants {
            participant.events.append(event)
        }
        
        try? context.save()
        dismiss()
    }
    
    private func getOrCreateCurrentUser() -> ModelUser {
        // Для MVP создаём фиктивного "себя"
        // В будущем это будет настоящий профиль пользователя
        let fetchDescriptor = FetchDescriptor<ModelUser>(
            predicate: #Predicate { $0.name == "Я" }
        )
        
        if let existingUser = try? context.fetch(fetchDescriptor).first {
            return existingUser
        }
        
        // Создаём нового пользователя "Я"
        let newUser = ModelUser(name: "Я")
        context.insert(newUser)
        return newUser
    }
}

// MARK: - User Picker

struct UserPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allUsers: [ModelUser]
    @Binding var selectedUsers: Set<ModelUser>
    let excludeUser: ModelUser?
    
    @State private var searchText = ""
    
    var availableUsers: [ModelUser] {
        allUsers.filter { user in
            // Исключаем уже выбранных и предзаполненного
            !selectedUsers.contains(user) &&
            user.id != excludeUser?.id &&
            user.name != "Я" && // Не показываем "себя"
            (searchText.isEmpty || user.name.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableUsers) { user in
                    Button(action: {
                        selectedUsers.insert(user)
                        dismiss()
                    }) {
                        HStack {
                            UserAvatarView(user: user, size: 40)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                if let profession = user.profession {
                                    Text(profession)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Поиск контакта")
            .navigationTitle("Добавить участника")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .overlay {
                if availableUsers.isEmpty {
                    ContentUnavailableView(
                        "Нет доступных контактов",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text("Добавьте контакты чтобы пригласить их в событие")
                    )
                }
            }
        }
    }
}

// MARK: - Helper Views

struct UserAvatarView: View {
    let user: ModelUser
    let size: CGFloat
    
    var body: some View {
        if let avatarUrl = user.avatarUrl {
            AsyncImage(url: avatarUrl) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: size, height: size)
            .overlay {
                Text(user.name.prefix(1).uppercased())
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.white)
            }
    }
}

#Preview("Обычное создание") {
    AddEventView()
        .modelContainer(for: [ModelUser.self, ModelMessage.self, ModelEvent.self])
}

#Preview("С предзаполненным участником") {
    let user = ModelUser(name: "Данис", profession: "Designer")
    return AddEventView(preselectedUser: user)
        .modelContainer(for: [ModelUser.self, ModelMessage.self, ModelEvent.self])
}
