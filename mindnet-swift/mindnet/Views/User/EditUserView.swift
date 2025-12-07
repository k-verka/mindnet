//
//  EditUserView.swift
//  mindnet
//
//  Created by wv on 29/11/2025.
//

import SwiftUI
import SwiftData

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
