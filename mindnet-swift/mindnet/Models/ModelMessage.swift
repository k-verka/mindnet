//
//  ModelMessage.swift
//  mindnet
//
//  Created by wv on 26/11/2025.
//

import Foundation
import SwiftData

/// Универсальное сообщение: личная заметка ИЛИ комментарий в событии
@Model
public final class ModelMessage: Identifiable {
    /// Уникальный идентификатор
    public var id: UUID
    
    /// Текст сообщения
    public var content: String
    
    /// Дата создания/события
    public var date: Date
    
    /// Тип события (встреча, звонок, сообщение, и т.д.) - для личных заметок
    public var eventType: String?
    
    /// Автор сообщения (кто написал)
    public var author: ModelUser?
    
    /// Связь с пользователем (если это личная заметка О ком-то)
    public var relatedUser: ModelUser?
    
    /// Связь с событием (если это комментарий В событии)
    public var relatedEvent: ModelEvent?
    
    /// Фотографии, прикрепленные к сообщению
    public var photoPaths: [String]
    
    /// Является ли сообщение приватным (личная заметка vs публичный комментарий)
    public var isPrivate: Bool
    
    public init(
        id: UUID = UUID(),
        content: String,
        date: Date = Date(),
        eventType: String? = nil,
        author: ModelUser? = nil,
        relatedUser: ModelUser? = nil,
        relatedEvent: ModelEvent? = nil,
        photoPaths: [String] = [],
        isPrivate: Bool = true
    ) {
        self.id = id
        self.content = content
        self.date = date
        self.eventType = eventType
        self.author = author
        self.relatedUser = relatedUser
        self.relatedEvent = relatedEvent
        self.photoPaths = photoPaths
        self.isPrivate = isPrivate
    }
}
