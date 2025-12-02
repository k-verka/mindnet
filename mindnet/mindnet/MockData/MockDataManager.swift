//
//  MockDataManager.swift
//  mindnet
//
//  Created by wv on 27/11/2025.
//

import Foundation
import SwiftData

class MockDataManager {
    static func createMockData(context: ModelContext) {
        // Проверяем, есть ли уже данные
        let fetchDescriptor = FetchDescriptor<ModelUser>()
        if let existingUsers = try? context.fetch(fetchDescriptor), !existingUsers.isEmpty {
            print("Mock data already exists")
            return
        }
        
        print("Creating mock data...")
        
        // Создаём текущего пользователя (себя)
        let me = ModelUser(
            name: "Я",
            birthdate: Calendar.current.date(byAdding: .year, value: -28, to: Date()),
            city: "Amsterdam",
            profession: "Product Manager",
            skills: ["Swift", "SwiftUI", "Product Design"],
            tags: ["Технологии", "Стартапы"]
        )
        context.insert(me)
        
        // Создаём контакты
        let contacts = createContacts()
        contacts.forEach { context.insert($0) }
        
        // Создаём события
        let events = createEvents(me: me, contacts: contacts)
        events.forEach { context.insert($0) }
        
        // Создаём комментарии в событиях
        createComments(for: events, from: [me] + contacts, context: context)
        
        // Создаём личные заметки
        createPersonalNotes(for: contacts, author: me, context: context)
        
        // Сохраняем
        try? context.save()
        
        print("Mock data created successfully!")
    }
    
    // MARK: - Create Contacts
    
    private static func createContacts() -> [ModelUser] {
        var contacts: [ModelUser] = []
        
        // Контакт 1: Данис
        let danis = ModelUser(
            name: "Данис Хамидуллин",
            birthdate: Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 15)),
            city: "Москва",
            profession: "UI/UX Designer",
            skills: ["Figma", "Sketch", "Adobe XD", "Prototyping"],
            tags: ["Друзья", "Дизайн", "Коллеги"]
        )
        contacts.append(danis)
        
        // Контакт 2: Иван
        let ivan = ModelUser(
            name: "Иван Петров",
            birthdate: Calendar.current.date(from: DateComponents(year: 1993, month: 7, day: 22)),
            city: "Санкт-Петербург",
            profession: "Backend Developer",
            skills: ["Python", "Django", "PostgreSQL", "Docker"],
            tags: ["Коллеги", "Разработка"]
        )
        contacts.append(ivan)
        
        // Контакт 3: Мария
        let maria = ModelUser(
            name: "Мария Иванова",
            birthdate: Calendar.current.date(from: DateComponents(year: 1996, month: 11, day: 5)),
            city: "Amsterdam",
            profession: "Marketing Manager",
            skills: ["SMM", "Content", "Analytics"],
            tags: ["Друзья", "Маркетинг"]
        )
        contacts.append(maria)
        
        // Контакт 4: Алексей
        let alex = ModelUser(
            name: "Алексей Сидоров",
            birthdate: Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 30)),
            city: "Берлин",
            profession: "Product Designer",
            skills: ["Design Systems", "iOS Design", "User Research"],
            tags: ["Коллеги", "Дизайн", "Менторы"]
        )
        contacts.append(alex)
        
        // Контакт 5: Анна
        let anna = ModelUser(
            name: "Анна Смирнова",
            birthdate: Calendar.current.date(from: DateComponents(year: 1994, month: 6, day: 18)),
            city: "Москва",
            profession: "Frontend Developer",
            skills: ["React", "TypeScript", "CSS", "JavaScript"],
            tags: ["Друзья", "Разработка"]
        )
        contacts.append(anna)
        
        // Контакт 6: Дмитрий
        let dmitry = ModelUser(
            name: "Дмитрий Козлов",
            birthdate: Calendar.current.date(from: DateComponents(year: 1992, month: 12, day: 25)),
            city: "Лондон",
            profession: "Data Scientist",
            skills: ["Python", "Machine Learning", "TensorFlow"],
            tags: ["Университет", "Наука"]
        )
        contacts.append(dmitry)
        
        return contacts
    }
    
    // MARK: - Create Events
    
    private static func createEvents(me: ModelUser, contacts: [ModelUser]) -> [ModelEvent] {
        var events: [ModelEvent] = []
        
        // Событие 1: Новый год 2024
        let newYear = ModelEvent(
            title: "Новый год 2024",
            eventDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 0, minute: 0))!,
            eventDescription: "Встретили новый год у Даниса дома. Было круто!",
            creator: me,
            participants: [me, contacts[0], contacts[2], contacts[4]], // Данис, Мария, Анна
            participantRoles: [
                me.id: "creator",
                contacts[0].id: "participant",
                contacts[2].id: "participant",
                contacts[4].id: "participant"
            ]
        )
        me.events.append(newYear)
        contacts[0].events.append(newYear)
        contacts[2].events.append(newYear)
        contacts[4].events.append(newYear)
        events.append(newYear)
        
        // Событие 2: День рождения Ивана
        let ivanBday = ModelEvent(
            title: "День рождения Ивана",
            eventDate: Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 22, hour: 18, minute: 0))!,
            eventDescription: "Праздновали в ресторане в центре Питера",
            creator: contacts[1], // Иван
            participants: [me, contacts[1], contacts[4]], // Я, Иван, Анна
            participantRoles: [
                me.id: "participant",
                contacts[1].id: "creator",
                contacts[4].id: "participant"
            ]
        )
        me.events.append(ivanBday)
        contacts[1].events.append(ivanBday)
        contacts[4].events.append(ivanBday)
        events.append(ivanBday)
        
        // Событие 3: Конференция Design Conf
        let conference = ModelEvent(
            title: "Design Conf 2024",
            eventDate: Calendar.current.date(from: DateComponents(year: 2024, month: 5, day: 15, hour: 10, minute: 0))!,
            eventDescription: "Конференция по дизайну в Берлине. Познакомились с крутыми дизайнерами!",
            creator: me,
            participants: [me, contacts[0], contacts[3]], // Данис, Алексей
            participantRoles: [
                me.id: "creator",
                contacts[0].id: "participant",
                contacts[3].id: "participant"
            ]
        )
        me.events.append(conference)
        contacts[0].events.append(conference)
        contacts[3].events.append(conference)
        events.append(conference)
        
        // Событие 4: Поездка в Амстердам
        let amsterdam = ModelEvent(
            title: "Поездка в Амстердам",
            eventDate: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 10, hour: 12, minute: 0))!,
            eventDescription: "Показывали Марии город, гуляли по каналам",
            creator: me,
            participants: [me, contacts[2]], // Мария
            participantRoles: [
                me.id: "creator",
                contacts[2].id: "participant"
            ]
        )
        me.events.append(amsterdam)
        contacts[2].events.append(amsterdam)
        events.append(amsterdam)
        
        // Событие 5: Hackathon
        let hackathon = ModelEvent(
            title: "AI Hackathon",
            eventDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 20, hour: 9, minute: 0))!,
            eventDescription: "48 часов кодинга. Заняли 2 место!",
            creator: contacts[1], // Иван
            participants: [me, contacts[1], contacts[4], contacts[5]], // Иван, Анна, Дмитрий
            participantRoles: [
                me.id: "creator",
                contacts[1].id: "creator",
                contacts[4].id: "participant",
                contacts[5].id: "participant"
            ]
        )
        me.events.append(hackathon)
        contacts[1].events.append(hackathon)
        contacts[4].events.append(hackathon)
        contacts[5].events.append(hackathon)
        events.append(hackathon)
        
        return events
    }
    
    // MARK: - Create Comments
    
    private static func createComments(for events: [ModelEvent], from users: [ModelUser], context: ModelContext) {
        // Комментарии для Нового года
        if events.count > 0 {
            let event = events[0]
            
            let comment1 = ModelMessage(
                content: "Было круто! Помню как мы запускали фейерверки на крыше 🎆",
                date: Calendar.current.date(byAdding: .hour, value: -48, to: Date())!,
                author: users[1], // Данис
                relatedEvent: event,
                isPrivate: false
            )
            context.insert(comment1)
            event.comments.append(comment1)
            users[1].authoredMessages.append(comment1)
            
            let comment2 = ModelMessage(
                content: "Лучший новый год в жизни! Спасибо что пригласили 💙",
                date: Calendar.current.date(byAdding: .hour, value: -36, to: Date())!,
                author: users[3], // Мария
                relatedEvent: event,
                isPrivate: false
            )
            context.insert(comment2)
            event.comments.append(comment2)
            users[3].authoredMessages.append(comment2)
        }
        
        // Комментарии для ДР Ивана
        if events.count > 1 {
            let event = events[1]
            
            let comment3 = ModelMessage(
                content: "Спасибо всем кто пришёл! 🎂",
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                author: users[2], // Иван
                relatedEvent: event,
                isPrivate: false
            )
            context.insert(comment3)
            event.comments.append(comment3)
            users[2].authoredMessages.append(comment3)
        }
        
        // Комментарии для конференции
        if events.count > 2 {
            let event = events[2]
            
            let comment4 = ModelMessage(
                content: "Познакомился с дизайнерами из Figma, получил кучу инсайтов!",
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                author: users[1], // Данис
                relatedEvent: event,
                isPrivate: false
            )
            context.insert(comment4)
            event.comments.append(comment4)
            users[1].authoredMessages.append(comment4)
            
            let comment5 = ModelMessage(
                content: "Доклад про design systems был огонь 🔥",
                date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
                author: users[4], // Алексей
                relatedEvent: event,
                isPrivate: false
            )
            context.insert(comment5)
            event.comments.append(comment5)
            users[4].authoredMessages.append(comment5)
        }
        
        // Комментарии для хакатона
        if events.count > 4 {
            let event = events[4]
            
            let comment6 = ModelMessage(
                content: "48 часов без сна, но оно того стоило! 💪",
                date: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!,
                author: users[5], // Анна
                relatedEvent: event,
                isPrivate: false
            )
            context.insert(comment6)
            event.comments.append(comment6)
            users[5].authoredMessages.append(comment6)
            
            let comment7 = ModelMessage(
                content: "ML модель которую мы сделали реально работает! Уже используем в продакшене",
                date: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!,
                author: users[6], // Дмитрий
                relatedEvent: event,
                isPrivate: false
            )
            context.insert(comment7)
            event.comments.append(comment7)
            users[6].authoredMessages.append(comment7)
        }
    }
    
    // MARK: - Create Personal Notes
    
    private static func createPersonalNotes(for contacts: [ModelUser], author: ModelUser, context: ModelContext) {
        // Заметка о Данисе
        let note1 = ModelMessage(
            content: "Познакомились на конференции в 2023. Крутой дизайнер, всегда помогает с фидбеком.",
            date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            eventType: "Встреча",
            author: author,
            relatedUser: contacts[0],
            isPrivate: true
        )
        context.insert(note1)
        contacts[0].messages.append(note1)
        author.authoredMessages.append(note1)
        
        // Заметка об Иване
        let note2 = ModelMessage(
            content: "Работали вместе над backend'ом проекта. Очень сильный в Python.",
            date: Calendar.current.date(byAdding: .day, value: -45, to: Date())!,
            eventType: "Звонок",
            author: author,
            relatedUser: contacts[1],
            isPrivate: true
        )
        context.insert(note2)
        contacts[1].messages.append(note2)
        author.authoredMessages.append(note2)
        
        // Заметка о Марии
        let note3 = ModelMessage(
            content: "Переехала в Амстердам месяц назад. Показывал город, теперь часто встречаемся.",
            date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
            author: author,
            relatedUser: contacts[2],
            isPrivate: true
        )
        context.insert(note3)
        contacts[2].messages.append(note3)
        author.authoredMessages.append(note3)
    }
}
