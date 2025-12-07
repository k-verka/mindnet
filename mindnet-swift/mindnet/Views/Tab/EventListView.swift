//
//  EventListView.swift
//  mindnet
//
//  Created by wv on 29/11/2025.
//
import SwiftUI
import SwiftData

struct EventListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ModelEvent.eventDate, order: .reverse) private var events: [ModelEvent]
    @State private var showingAddEvent = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        EventRowView(event: event)
                    }
                }
            }
            .navigationTitle("События")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView()
            }
            .overlay {
                if events.isEmpty {
                    ContentUnavailableView(
                        "Нет событий",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Создайте первое событие или добавьте через контакт")
                    )
                }
            }
        }
    }
}
