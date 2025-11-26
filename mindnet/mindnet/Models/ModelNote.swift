//
//  ModelNote.swift
//  mindnet
//
//  Created by wv on 26/11/2025.
//

import Foundation
import SwiftData

/// Заметка о взаимодействии с контактом
@Model
public final class ModelNote: Identifiable {
    /// Уникальный идентификатор
    public var id: UUID
    
    /// Текст заметки
    public var content: String
    
    /// Дата создания/события
    public var date: Date
    
    /// Тип события (встреча, звонок, сообщение, и т.д.)
    public var eventType: String?
    
    /// Обратная связь с пользователем
    public var user: ModelUser?
    
    public init(
        id: UUID = UUID(),
        content: String,
        date: Date = Date(),
        eventType: String? = nil,
        user: ModelUser? = nil
    ) {
        self.id = id
        self.content = content
        self.date = date
        self.eventType = eventType
        self.user = user
    }
}
