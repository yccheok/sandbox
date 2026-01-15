//
//  ContentView.swift
//  yyy
//
//  Created by Yan Cheng Cheok on 08/01/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var isSheetPresented = false
    
    var body: some View {
        Button("Show Sheet") {
            isSheetPresented.toggle()
        }
        .sheet(isPresented: $isSheetPresented) {
            SheetContentView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct SheetContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(1...30, id: \.self) { index in
                    Text("Item \(index)")
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}
