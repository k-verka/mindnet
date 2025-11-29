//
//  EventRowView.swift
//  mindnet
//
//  Created by wv on 29/11/2025.
//
import SwiftUI
import SwiftData

struct EventRowView: View {
    let event: ModelEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка события
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                Image(systemName: "calendar")
                    .foregroundStyle(.purple)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                Text(event.eventDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    // Участники
                    Label("\(event.participants.count)", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Комментарии
                    Label("\(event.comments.count)", systemImage: "message.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Фото
                    if !event.photoPaths.isEmpty {
                        Label("\(event.photoPaths.count)", systemImage: "photo.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
