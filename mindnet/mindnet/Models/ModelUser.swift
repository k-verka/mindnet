//
//  ModelUser.swift
//  mindnet
//
//  Created by wv on 24/11/2025.
//

import Foundation
import SwiftData
/// Ползователь/Контакт
@Model
public final class ModelUser: Identifiable {
    /// Уникальный идентификатор
    public var id: UUID

    /// Имя
    public var name: String

    /// Дата рождения
    public var birthdate: Date?

    /// Город проживания
    public var city: String?

    /// Специальность/профессия
    public var profession: String?

    /// Навыки — массив строк
    public var skills: [String]

    /// Теги — массив строк
    public var tags: [String]

    /// Связанные заметки/воспоминания
    public var notes: [ModelNote]

    /// Контакты (мессенджеры/ссылки) — словарь <тип, значение>
    public var contacts: [String: String]

    /// Фото (URL аватара)
    public var avatarUrl: URL?

    public init(
        id: UUID = UUID(),
        name: String,
        birthdate: Date? = nil,
        city: String? = nil,
        profession: String? = nil,
        skills: [String] = [],
        tags: [String] = [],
        notes: [ModelNote] = [],
        contacts: [String: String] = [:],
        avatarUrl: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.birthdate = birthdate
        self.city = city
        self.profession = profession
        self.skills = skills
        self.tags = tags
        self.notes = notes
        self.contacts = contacts
        self.avatarUrl = avatarUrl
    }
}
