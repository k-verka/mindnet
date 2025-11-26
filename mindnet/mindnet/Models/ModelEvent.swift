//
//  ModelEvent.swift
//  mindnet
//
//  Created by wv on 26/11/2025.
//

import Foundation
import SwiftData

/// Событие с несколькими участниками
@Model
public final class ModelEvent: Identifiable {
    /// Уникальный идентификатор
    public var id: UUID
    
    /// Название события
    public var title: String
    
    /// Дата события
    public var eventDate: Date
    
    /// Описание события (опционально)
    public var eventDescription: String?
    
    /// Создатель события
    public var creator: ModelUser?
    
    /// Участники события
    public var participants: [ModelUser]
    
    /// Роли участников (UUID пользователя → роль)
    /// Роли: "creator" (организатор) или "participant" (участник)
    public var participantRoles: [UUID: String]
    
    /// Комментарии к событию
    public var comments: [ModelMessage]
    
    /// Обложка события (главное фото)
    public var coverPhotoPath: String?
    
    /// Все фотографии события
    public var photoPaths: [String]
    
    /// Дата создания записи
    public var createdAt: Date
    
    /// Дата последнего обновления
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        eventDate: Date,
        eventDescription: String? = nil,
        creator: ModelUser? = nil,
        participants: [ModelUser] = [],
        participantRoles: [UUID: String] = [:],
        comments: [ModelMessage] = [],
        coverPhotoPath: String? = nil,
        photoPaths: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.eventDate = eventDate
        self.eventDescription = eventDescription
        self.creator = creator
        self.participants = participants
        self.participantRoles = participantRoles
        self.comments = comments
        self.coverPhotoPath = coverPhotoPath
        self.photoPaths = photoPaths
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Helper Methods
    
    /// Проверяет, является ли пользователь организатором
    public func isCreator(_ user: ModelUser) -> Bool {
        return participantRoles[user.id] == "creator"
    }
    
    /// Проверяет, может ли пользователь редактировать событие
    public func canEdit(_ user: ModelUser) -> Bool {
        return isCreator(user)
    }
    
    /// Проверяет, может ли пользователь удалить комментарий
    public func canDeleteComment(_ user: ModelUser, comment: ModelMessage) -> Bool {
        return isCreator(user) || comment.author?.id == user.id
    }
    
    /// Проверяет, может ли пользователь управлять участниками
    public func canManageParticipants(_ user: ModelUser) -> Bool {
        return isCreator(user)
    }
}
