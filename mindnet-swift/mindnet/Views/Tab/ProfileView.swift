//
//  ProfileView.swift
//  mindnet
//
//  Created by wv on 29/11/2025.
//
import SwiftUI
import SwiftData

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Настройки") {
                    Label("Уведомления", systemImage: "bell.fill")
                    Label("О приложении", systemImage: "info.circle.fill")
                }
            }
            .navigationTitle("Профиль")
        }
    }
}
