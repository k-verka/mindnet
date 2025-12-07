//
//  EventDetailView.swift
//  mindnet
//
//  Created by wv on 26/11/2025.
//

import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Bindable var event: ModelEvent
    @Environment(\.modelContext) private var context
    @State private var currentUser: ModelUser?
    
    @State private var showingAddComment = false
    @State private var showingAddParticipant = false
    @State private var showingEditEvent = false
    @State private var showingManageParticipants = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddEventPhotos = false
    @State private var selectedEventImages: [UIImage] = []
    
    var isCreator: Bool {
        guard let user = currentUser else { return false }
        return event.isCreator(user)
    }
    
    var body: some View {
        List {
            // Основная информация
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(event.eventDate, style: .date)
                        Text("•")
                        Text(event.eventDate, style: .time)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if let description = event.eventDescription {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Участники
            Section {
                ForEach(event.participants) { participant in
                    HStack {
                        UserAvatarView(user: participant, size: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(participant.name)
                                .font(.headline)
                            
                            if event.isCreator(participant) {
                                Text("Организатор")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .cornerRadius(4)
                            } else {
                                Text("Участник")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Показываем корону для организатора
                        if event.isCreator(participant) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                
                Button(action: { showingAddParticipant = true }) {
                    Label("Добавить участника", systemImage: "plus.circle.fill")
                }
                
                if isCreator {
                    Button(action: { showingManageParticipants = true }) {
                        Label("Управление участниками", systemImage: "person.2.badge.gearshape")
                    }
                }
            } header: {
                HStack {
                    Text("Участники (\(event.participants.count))")
                    Spacer()
                }
            }
            
            // Фото события
            Section("Фото") {
                if !event.photoPaths.isEmpty {
                    PhotoGridView(
                        photoPaths: event.photoPaths,
                        onDelete: isCreator ? { path in
                            deleteEventPhoto(path)
                        } : nil
                    )
                }
                
                AddPhotosButton(
                    selectedImages: $selectedEventImages,
                    selectionLimit: 20
                )
            }
            .onChange(of: selectedEventImages) { oldValue, newValue in
                if !newValue.isEmpty {
                    addEventPhotos(newValue)
                    selectedEventImages = []
                }
            }
            
            // Комментарии
            Section {
                Button(action: { showingAddComment = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Написать комментарий")
                    }
                }
                
                ForEach(event.comments.sorted(by: { $0.date > $1.date })) { comment in
                    CommentRowView(
                        comment: comment,
                        canDelete: canDeleteComment(comment),
                        onDelete: { deleteComment(comment) }
                    )
                }
            } header: {
                Text("Комментарии (\(event.comments.count))")
            }
        }
        .navigationTitle("Событие")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isCreator {
                    Menu {
                        Button(action: { showingEditEvent = true }) {
                            Label("Редактировать", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Удалить событие", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddComment) {
            AddCommentView(event: event, currentUser: currentUser)
        }
        .sheet(isPresented: $showingAddParticipant) {
            UserPickerView(selectedUsers: .constant(Set()), excludeUser: nil)
                .overlay(alignment: .bottom) {
                    // Для добавления участников в событие
                    // TODO: Implement proper participant adding
                }
        }
        .sheet(isPresented: $showingEditEvent) {
            EditEventView(event: event)
        }
        .sheet(isPresented: $showingManageParticipants) {
            ManageParticipantsView(event: event, currentUser: currentUser)
        }
        .confirmationDialog("Удалить событие?", isPresented: $showingDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                deleteEvent()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Это действие нельзя отменить. Все комментарии и фото будут удалены.")
        }
        .onAppear {
            currentUser = getOrCreateCurrentUser()
        }
    }
    
    private func canDeleteComment(_ comment: ModelMessage) -> Bool {
        guard let user = currentUser else { return false }
        return event.canDeleteComment(user, comment: comment)
    }
    
    private func deleteComment(_ comment: ModelMessage) {
        // Удаляем фото комментария
        PhotoManager.shared.deletePhotos(comment.photoPaths)
        
        event.comments.removeAll { $0.id == comment.id }
        context.delete(comment)
        event.updatedAt = Date()
        try? context.save()
    }
    
    private func deleteEvent() {
        // Удаляем фото события
        PhotoManager.shared.deletePhotos(event.photoPaths)
        
        // Удаляем фото из комментариев
        for comment in event.comments {
            PhotoManager.shared.deletePhotos(comment.photoPaths)
        }
        
        // Удаляем событие из списка событий всех участников
        for participant in event.participants {
            participant.events.removeAll { $0.id == event.id }
        }
        
        // Удаляем все комментарии
        for comment in event.comments {
            context.delete(comment)
        }
        
        context.delete(event)
        try? context.save()
    }
    
    private func addEventPhotos(_ images: [UIImage]) {
        let photoPaths = PhotoManager.shared.savePhotos(images)
        event.photoPaths.append(contentsOf: photoPaths)
        event.updatedAt = Date()
        try? context.save()
    }
    
    private func deleteEventPhoto(_ path: String) {
        PhotoManager.shared.deletePhoto(path)
        event.photoPaths.removeAll { $0 == path }
        event.updatedAt = Date()
        try? context.save()
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

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: ModelMessage
    let canDelete: Bool
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let author = comment.author {
                    UserAvatarView(user: author, size: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.author?.name ?? "Неизвестный")
                        .font(.subheadline)
                        .bold()
                    
                    Text(comment.date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if canDelete {
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Text(comment.content)
                .font(.body)
            
            // Фото в комментарии
            if !comment.photoPaths.isEmpty {
                PhotoGridView(photoPaths: comment.photoPaths)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("Удалить комментарий?", isPresented: $showingDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                onDelete()
            }
            Button("Отмена", role: .cancel) { }
        }
    }
}

// MARK: - Add Comment View

struct AddCommentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    let event: ModelEvent
    let currentUser: ModelUser?
    
    @State private var content = ""
    @State private var date = Date()
    @State private var selectedImages: [UIImage] = []
    @State private var savedPhotoPaths: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Дата", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Комментарий") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
                
                Section("Фото") {
                    // Показываем выбранные фото
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Button(action: { selectedImages.remove(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .background(Circle().fill(Color.red))
                                                .font(.title3)
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    AddPhotosButton(selectedImages: $selectedImages, selectionLimit: 10)
                }
            }
            .navigationTitle("Новый комментарий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Опубликовать") {
                        saveComment()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func saveComment() {
        guard let author = currentUser else { return }
        
        // Сохраняем фото
        let photoPaths = PhotoManager.shared.savePhotos(selectedImages)
        
        let comment = ModelMessage(
            content: content,
            date: date,
            author: author,
            relatedEvent: event,
            photoPaths: photoPaths,
            isPrivate: false  // Комментарии в событиях - публичные
        )
        
        context.insert(comment)
        event.comments.append(comment)
        author.authoredMessages.append(comment)
        event.updatedAt = Date()
        
        try? context.save()
        dismiss()
    }
}

// MARK: - Edit Event View

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: ModelEvent
    
    @State private var title: String
    @State private var eventDate: Date
    @State private var eventDescription: String
    
    init(event: ModelEvent) {
        self.event = event
        _title = State(initialValue: event.title)
        _eventDate = State(initialValue: event.eventDate)
        _eventDescription = State(initialValue: event.eventDescription ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Информация о событии") {
                    TextField("Название", text: $title)
                    
                    DatePicker("Дата", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "ru_RU"))
                    
                    TextField("Описание", text: $eventDescription, axis: .vertical)
                        .lineLimit(3...6)
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
        event.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        event.eventDate = eventDate
        event.eventDescription = eventDescription.isEmpty ? nil : eventDescription
        event.updatedAt = Date()
        dismiss()
    }
}

// MARK: - Manage Participants View

struct ManageParticipantsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: ModelEvent
    let currentUser: ModelUser?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(event.participants) { participant in
                    HStack {
                        UserAvatarView(user: participant, size: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(participant.name)
                                .font(.headline)
                            
                            if event.isCreator(participant) {
                                Text("Организатор")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .cornerRadius(4)
                            } else {
                                Text("Участник")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if participant.id != currentUser?.id {
                            Menu {
                                if !event.isCreator(participant) {
                                    Button(action: { makeCreator(participant) }) {
                                        Label("Сделать организатором", systemImage: "crown")
                                    }
                                }
                                
                                Button(role: .destructive, action: { removeParticipant(participant) }) {
                                    Label("Удалить из события", systemImage: "person.badge.minus")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Управление участниками")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
    
    private func makeCreator(_ participant: ModelUser) {
        event.participantRoles[participant.id] = "creator"
        event.updatedAt = Date()
    }
    
    private func removeParticipant(_ participant: ModelUser) {
        event.participants.removeAll { $0.id == participant.id }
        event.participantRoles.removeValue(forKey: participant.id)
        participant.events.removeAll { $0.id == event.id }
        event.updatedAt = Date()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ModelUser.self, ModelMessage.self, ModelEvent.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let user1 = ModelUser(name: "Данис", profession: "Designer")
    let user2 = ModelUser(name: "Иван", profession: "Developer")
    let creator = ModelUser(name: "Я")
    
    container.mainContext.insert(user1)
    container.mainContext.insert(user2)
    container.mainContext.insert(creator)
    
    let event = ModelEvent(
        title: "Новый год 2024",
        eventDate: Date(),
        eventDescription: "Встретили новый год вместе!",
        creator: creator,
        participants: [creator, user1, user2],
        participantRoles: [
            creator.id: "creator",
            user1.id: "participant",
            user2.id: "participant"
        ]
    )
    
    let comment1 = ModelMessage(
        content: "Было круто!",
        author: user1,
        relatedEvent: event,
        isPrivate: false
    )
    
    let comment2 = ModelMessage(
        content: "Супер вечер!",
        author: user2,
        relatedEvent: event,
        isPrivate: false
    )
    
    event.comments = [comment1, comment2]
    container.mainContext.insert(event)
    
    return NavigationStack {
        EventDetailView(event: event)
    }
    .modelContainer(container)
}
