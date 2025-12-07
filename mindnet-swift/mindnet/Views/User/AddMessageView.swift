//
//  AddMessageView.swift
//  mindnet
//
//  Created by wv on 29/11/2025.
//

import SwiftUI
import SwiftData

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
