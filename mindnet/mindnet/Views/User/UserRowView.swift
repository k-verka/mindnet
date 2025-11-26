import SwiftUI
import SwiftData

struct UserRowView: View {
    let user: ModelUser

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Placeholder avatar with initials
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                Text(initials(from: user.name))
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let profession = user.profession, !profession.isEmpty {
                        Label(profession, systemImage: "briefcase")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let city = user.city, !city.isEmpty {
                        Label(city, systemImage: "mappin.and.ellipse")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                if !user.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(user.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(Color.secondary.opacity(0.12))
                                    )
                            }
                        }
                    }
                    .frame(maxHeight: 20)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? String(name.prefix(1)) : initials
    }
}

#Preview("UserRowView") {
    let user = ModelUser(
        name: "Иван Петров",
        birthdate: Date(),
        city: "Москва",
        profession: "Designer",
        skills: ["Figma", "Sketch"],
        tags: ["Коллеги", "Дизайн"]
    )
    return List { UserRowView(user: user) }
}
