//
//  ContentView.swift
//  zzz
//
//  Created by Yan Cheng Cheok on 08/01/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScreenA()
        }
    }
}

struct ScreenA: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Screen A")
                .font(.largeTitle)

            NavigationLink("Go to Screen B") {
                ScreenB()
            }
        }
        .toolbar {
            // Equivalent to navigationItem.title
            ToolbarItem(placement: .principal) {
                Text("Home")
                    .font(.headline)
            }

            // Equivalent to rightBarButtonItem
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    print("Add tapped")
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct ScreenB: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Screen B")
                .font(.largeTitle)
        }
        .toolbar {

            // CENTER (principal)
            ToolbarItem(placement: .principal) {
                Text("午餐 ▾")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    print("Share tapped")
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                Button {
                    print("Favorite tapped")
                } label: {
                    Image(systemName: "star")
                }
            }
        }
    }
}

struct CircleButton: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.black)
            .padding(10)
            .background(Circle().fill(.white))
            .shadow(radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
