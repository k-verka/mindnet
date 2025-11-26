//
//  UserDetailView.swift
//  mindnet
//
//  Created by wv on 26/11/2025.
//

import SwiftUI
import SwiftData

struct UserDetailView: View {
    @Bindable var user: ModelUser
    @Environment(\.modelContext) private var context
    @State private var showingEditSheet = false
    @State private var showingAddMessage = false
    @State private var showingEventOptions = false
    @State private var showingCreateEvent = false
    @State private var showingAddToEvent = false
    
    var body: some View {
        List {
            // Основная информация
            Section {
                HStack {
                    if let avatarUrl = user.avatarUrl {
                        AsyncImage(url: avatarUrl) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            avatarPlaceholder
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else {
                        avatarPlaceholder
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(user.name)
                            .font(.title2)
                            .bold()
                        
                        if let profession = user.profession {
                            Text(profession)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let city = user.city {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text(city)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                if let birthdate = user.birthdate {
                    HStack {
                        Image(systemName: "gift.fill")
                        Text("День рождения")
                        Spacer()
                        Text(birthdate, style: .date)
                    }
                    
                    if let age = calculateAge(from: birthdate) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("Возраст")
                            Spacer()
                            Text("\(age) лет")
                        }
                    }
                }
            }
            
            // Навыки
            if !user.skills.isEmpty {
                Section("Навыки") {
                    ForEach(user.skills, id: \.self) { skill in
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(skill)
                        }
                    }
                }
            }
            
            // Теги
            if !user.tags.isEmpty {
                Section("Теги") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(user.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Контакты
            if !user.contacts.isEmpty {
                Section("Контакты") {
                    ForEach(Array(user.contacts.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(user.contacts[key] ?? "")
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            // События с этим человеком
            Section {
                // Кнопка создания события
                Button(action: { showingEventOptions = true }) {
                    Label("Создать событие с \(user.name)", systemImage: "calendar.badge.plus")
                }
                
                // Список существующих событий
                ForEach(user.events.sorted(by: { $0.eventDate > $1.eventDate })) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.headline)
                                Text(event.eventDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(event.participants.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("События")
            }
            
            // Личные заметки
            Section {
                Button(action: { showingAddMessage = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Добавить заметку")
                    }
                }
                
                ForEach(user.messages.filter { $0.isPrivate }.sorted(by: { $0.date > $1.date })) { message in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(message.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let eventType = message.eventType {
                                Text("• \(eventType)")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Text(message.content)
                            .font(.subheadline)
                        
                        // Показать фото если есть
                        if !message.photoPaths.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(message.photoPaths, id: \.self) { path in
                                        Image(systemName: "photo")
                                            .font(.title3)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 60, height: 60)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Личные заметки")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Изменить") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditUserView(user: user)
        }
        .sheet(isPresented: $showingAddMessage) {
            AddMessageView(user: user)
        }
        .sheet(isPresented: $showingCreateEvent) {
            AddEventView(preselectedUser: user)
        }
        .confirmationDialog("Выберите действие", isPresented: $showingEventOptions) {
            Button("Создать новое событие") {
                showingCreateEvent = true
            }
            Button("Добавить в существующее") {
                showingAddToEvent = true
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Создайте новое событие с \(user.name) или добавьте в существующее")
        }
        .sheet(isPresented: $showingAddToEvent) {
            AddToExistingEventView(user: user)
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 80, height: 80)
            .overlay {
                Text(user.name.prefix(1).uppercased())
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            }
    }
    
    private func calculateAge(from birthdate: Date) -> Int? {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year
    }
}

struct EditUserView: View {
    @Bindable var user: ModelUser
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var birthdate: Date
    @State private var hasBirthdate: Bool
    @State private var city: String
    @State private var profession: String
    @State private var skillInput = ""
    @State private var skills: [String]
    @State private var tagInput = ""
    @State private var tags: [String]
    
    init(user: ModelUser) {
        self.user = user
        _name = State(initialValue: user.name)
        _birthdate = State(initialValue: user.birthdate ?? Date())
        _hasBirthdate = State(initialValue: user.birthdate != nil)
        _city = State(initialValue: user.city ?? "")
        _profession = State(initialValue: user.profession ?? "")
        _skills = State(initialValue: user.skills)
        _tags = State(initialValue: user.tags)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    TextField("Имя", text: $name)
                    
                    Toggle("Дата рождения", isOn: $hasBirthdate)
                    if hasBirthdate {
                        DatePicker("", selection: $birthdate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                    }
                    
                    TextField("Город", text: $city)
                    TextField("Профессия", text: $profession)
                }
                
                Section("Навыки") {
                    HStack {
                        TextField("Добавить навык", text: $skillInput)
                        Button("Добавить") {
                            if !skillInput.isEmpty {
                                skills.append(skillInput)
                                skillInput = ""
                            }
                        }
                    }
                    
                    ForEach(skills, id: \.self) { skill in
                        HStack {
                            Text(skill)
                            Spacer()
                            Button(action: { skills.removeAll { $0 == skill } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                
                Section("Теги") {
                    HStack {
                        TextField("Добавить тег", text: $tagInput)
                        Button("Добавить") {
                            if !tagInput.isEmpty {
                                tags.append(tagInput)
                                tagInput = ""
                            }
                        }
                    }
                    
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button(action: { tags.removeAll { $0 == tag } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        user.name = name
        user.birthdate = hasBirthdate ? birthdate : nil
        user.city = city.isEmpty ? nil : city
        user.profession = profession.isEmpty ? nil : profession
        user.skills = skills
        user.tags = tags
        dismiss()
    }
}

struct AddMessageView: View {
    let user: ModelUser
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var content = ""
    @State private var date = Date()
    @State private var eventType = ""
    
    let eventTypes = ["Встреча", "Звонок", "Сообщение", "Email", "Другое"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Дата", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Тип события", selection: $eventType) {
                        Text("Не выбрано").tag("")
                        ForEach(eventTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section("Заметка") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Новая заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveMessage()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func saveMessage() {
        let message = ModelMessage(
            content: content,
            date: date,
            eventType: eventType.isEmpty ? nil : eventType,
            author: user,
            relatedUser: user,
            isPrivate: true
        )
        
        context.insert(message)
        user.messages.append(message)
        dismiss()
    }
}

// Placeholder для EventDetailView (создадим на следующем шаге)
struct EventDetailView: View {
    let event: ModelEvent
    
    var body: some View {
        Text("Event Detail - Coming soon")
            .navigationTitle(event.title)
    }
}

// MARK: - Add To Existing Event

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
