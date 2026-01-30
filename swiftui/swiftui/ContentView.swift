//
//  ContentView.swift
//  swiftui
//
//  Created by Said Tura Saidazimov on 30.01.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ProfileScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            SettingsScreen()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            CounterScreen()
                .tabItem {
                    Label("Counter", systemImage: "plusminus")
                }
        }
    }
}

#Preview {
    ContentView()
}
