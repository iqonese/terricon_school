//
//  ProfileScreen.swift
//  swiftui
//
//  Created by Said Tura Saidazimov on 30.01.2026.
//

import SwiftUI



struct ProfileScreen: View {
    
    @State private var name: String = "John Smith"
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding()
                .background(Color.blue.opacity(0.2))
                .clipShape(Circle())
            
            Text(name)
                .font(.system(size: 24, weight: .bold))
            
            Button {
                name = "New name"
            } label: {
                Text("Edit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
        }
    }
}

#Preview {
    ProfileScreen()
}
