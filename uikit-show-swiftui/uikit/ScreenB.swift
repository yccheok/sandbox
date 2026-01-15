//
//  ScreenB.swift
//  uikit
//
//  Created by Yan Cheng Cheok on 08/01/2026.
//

import SwiftUI

struct ScreenB: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Screen B")
                .font(.largeTitle)
        }
        .toolbar {

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
