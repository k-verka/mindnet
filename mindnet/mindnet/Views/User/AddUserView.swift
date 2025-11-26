import SwiftUI
import SwiftData

struct AddUserView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String = ""
    @State private var hasBirthdate: Bool = false     // ← добавил
    @State private var birthdate: Date = Date()       // ← убрал optional
    @State private var city: String = ""
    @State private var profession: String = ""
    @State private var skillsText: String = ""
    @State private var tagsText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Имя", text: $name)
                    Toggle("Указать дату рождения", isOn: $hasBirthdate)
                    if hasBirthdate {
                        DatePicker("", selection: $birthdate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                    }
                    
                    TextField("Город", text: $city)
                    TextField("Профессия", text: $profession)
                }

                Section("Навыки и теги") {
                    TextField("Навыки (через запятую)", text: $skillsText)
                    TextField("Теги (через запятую)", text: $tagsText)
                }
            }
            .navigationTitle("Новый контакт")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let skills = skillsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let user = ModelUser(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            birthdate: hasBirthdate ? birthdate : nil,  // ← изменил
            city: city.isEmpty ? nil : city,
            profession: profession.isEmpty ? nil : profession,
            skills: skills,
            tags: tags
        )
        context.insert(user)
        try? context.save()
        dismiss()
    }
}

#Preview {
    AddUserView()
        .modelContainer(for: [ModelUser.self, ModelNote.self], inMemory: true)
}
