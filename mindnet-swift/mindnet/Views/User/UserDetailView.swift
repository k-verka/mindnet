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

