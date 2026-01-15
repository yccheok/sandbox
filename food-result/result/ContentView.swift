import SwiftUI

struct FoodLogView: View {
    // We keep this true so the sheet stays open like the design
    @State private var isSheetPresented = true
    @State private var sheetDetent: PresentationDetent = .medium
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background Image
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=1000&auto=format&fit=crop")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } placeholder: {
                Color.gray.edgesIgnoringSafeArea(.all)
            }
           
            // Top Navigation Bar
            HStack {
                CircleButton(icon: "chevron.left")
                Spacer()
                Text("午餐 ▾")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                Spacer()
                CircleButton(icon: "square.and.arrow.up")
                CircleButton(icon: "star")
            }
            .padding(.top, 60)
            .padding(.horizontal)
        }
        .sheet(isPresented: $isSheetPresented) {
            NutritionSheetContent(
                onExpandChange: { expanded in
                    withAnimation(.easeInOut) {
                        if expanded {
                            sheetDetent = .large
                        }
                    }
                }
            )
            .presentationDetents([.medium, .large], selection: $sheetDetent)
            .presentationCornerRadius(30)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
        }
    }
}

struct NutritionSheetContent: View {
    // 1. State to track expansion
    @State private var isExpanded: Bool = false
    let onExpandChange: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header: Title and Stepper (Unchanged)
                    HStack(alignment: .top) {
                        Text("豬肉炒飯配煎蛋")
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                        
                        HStack(spacing: 15) {
                            Image(systemName: "minus")
                                .foregroundColor(.blue)
                            Text("1")
                                .font(.title3)
                                .fontWeight(.bold)
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    // --- NUTRITION INFO CARD ---
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // 1. TOP SECTION (Summary + Button)
                        // We wrap this in a VStack and give it a zIndex of 1
                        // so it stays ON TOP of the sliding animation.
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 16) {
                                // Calories Header
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                        .padding(8)
                                        .background(Color.orange.opacity(0.15))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("熱量")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("635")
                                            .font(.title2)
                                            .fontWeight(.heavy)
                                    }
                                    Spacer()
                                }
                                
                                Divider()
                                
                                // Macros Row
                                HStack(spacing: 20) {
                                    MacroView(label: "碳水", value: "55.2", total: "193g", color: .yellow)
                                    MacroView(label: "蛋白質", value: "25.8", total: "70g", color: .green)
                                    MacroView(label: "脂肪", value: "18.4", total: "39g", color: .orange)
                                }
                            }
                            .padding()
                            
                            // Toggle Button
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isExpanded.toggle()
                                    onExpandChange(isExpanded)
                                }
                            }) {
                                HStack {
                                    Text(isExpanded ? "顯示較少" : "顯示更多")
                                    Image(systemName: "chevron.up")
                                        .rotationEffect(.degrees(isExpanded ? 0 : 180)) // Rotate arrow
                                }
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 16)
                                .contentShape(Rectangle()) // Makes the whole width tappable
                            }
                        }
                        .background(Color.white) // IMPORTANT: Solid background covers the sliding view
                        .zIndex(1) // IMPORTANT: Forces this layer to be on top of the expanded view
                        
                        // 2. EXPANDED DETAILED VIEW
                        // This sits at zIndex 0 (default), so it slides "out from under" the top section.
                        if isExpanded {
                            VStack(alignment: .leading, spacing: 20) {
                                Divider()
                                
                                Text("營養成分")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                VStack(spacing: 16) {
                                    NutritionDetailRow(label: "熱量", value: "495 Cal")
                                    NutritionDetailRow(label: "碳水", value: "55.2 g")
                                    
                                    HStack {
                                        Text("總糖量")
                                            .font(.subheadline)
                                            .foregroundColor(.gray.opacity(0.7))
                                        Spacer()
                                        Text("3.8 g")
                                            .font(.subheadline)
                                            .foregroundColor(.gray.opacity(0.7))
                                    }
                                    
                                    NutritionDetailRow(label: "蛋白質", value: "25.8 g")
                                }
                                .padding(.bottom, 16)
                            }
                            .padding(.horizontal)
                            .background(Color.white)
                            // The transition makes it slide down from the top edge of its own frame
                            .transition(.opacity)
                            .zIndex(0)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    // Apply clipping to the whole card so the animation doesn't bleed outside rounded corners
                    .clipped()
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Extra spacing
                    Color.clear.frame(height: 50)
                }
                .padding(.top, 30)
                .padding(.horizontal)
            }
            
            // Fixed Bottom Button (Unchanged)
            VStack {
                Button(action: {}) {
                    Text("記錄")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

// MARK: - Helper Views

struct NutritionDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.black)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.bold)
        }
    }
}

struct MacroView: View {
    let label: String
    let value: String
    let total: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.gray)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.15))
                        .frame(height: 6)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * 0.6, height: 6)
                }
            }
            .frame(height: 6)
            
            HStack(spacing: 0) {
                Text(value)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text("/\(total)")
                    .foregroundColor(.gray)
                    .font(.caption2)
            }
            .font(.footnote)
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
    FoodLogView()
}
