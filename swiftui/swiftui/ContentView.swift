//
//  ContentView.swift
//  swiftui
//
//  Created by Said Tura Saidazimov on 30.01.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView{
            ProfileView()
        }
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
