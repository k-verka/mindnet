//
//  ModelUser.swift
//  mindnet
//
//  Created by wv on 24/11/2025.
//

import Foundation
import SwiftData

/// Пользователь/Контакт
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

    /// Личные заметки о пользователе
    public var messages: [ModelMessage]

    /// Контакты (мессенджеры/ссылки) — словарь <тип, значение>
    public var contacts: [String: String]

    /// Фото (URL аватара)
    public var avatarUrl: URL?
    
    /// События, в которых участвует пользователь
    public var events: [ModelEvent]
    
    /// Сообщения, написанные пользователем (комментарии в событиях)
    public var authoredMessages: [ModelMessage]

    public init(
        id: UUID = UUID(),
        name: String,
        birthdate: Date? = nil,
        city: String? = nil,
        profession: String? = nil,
        skills: [String] = [],
        tags: [String] = [],
        messages: [ModelMessage] = [],
        contacts: [String: String] = [:],
        avatarUrl: URL? = nil,
        events: [ModelEvent] = [],
        authoredMessages: [ModelMessage] = []
    ) {
        self.id = id
        self.name = name
        self.birthdate = birthdate
        self.city = city
        self.profession = profession
        self.skills = skills
        self.tags = tags
        self.messages = messages
        self.contacts = contacts
        self.avatarUrl = avatarUrl
        self.events = events
        self.authoredMessages = authoredMessages
    }
}
