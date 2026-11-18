import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @Namespace private var animation
    @AppStorage("bookmarkedVehicles") private var bookmarkedRaw: String = ""
    
    let categories = ["All", "Sedan", "SUV", "EV", "Favourites"]
    
    var bookmarkedIDs: Set<String> {
        Set(bookmarkedRaw.split(separator: ",").map(String.init))
    }

    var bookmarkedVehicles: [Vehicle] {
        vehicleCatalogue.filter { bookmarkedIDs.contains($0.id) }
    }
    
    var filteredVehicles: [Vehicle] {
        vehicleCatalogue.filter { vehicle in
            if selectedCategory == "Favourites" {
                return bookmarkedIDs.contains(vehicle.id)
            }
            let matchesCategory = selectedCategory == "All" || vehicle.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                vehicle.name.localizedCaseInsensitiveContains(searchText) ||
                vehicle.brand.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        Text("VEHICLE CATALOGUE")
                            .font(AppFonts.screenTitle)
                            .foregroundColor(.white)
                            .tracking(2)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textTertiary)
                        TextField("Search vehicles...", text: $searchText)
                            .font(AppFonts.bodyText)
                            .foregroundColor(.white)
                            .submitLabel(.done)
                    }
                    .padding(12)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Category Filter (Liquid Glass Design)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = cat
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        if cat == "Favourites" {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(selectedCategory == cat ? .red : AppColors.textSecondary)
                                        }
                                        Text(cat)
                                            .font(.system(size: 13, weight: selectedCategory == cat ? .semibold : .medium))
                                            .foregroundColor(selectedCategory == cat ? .white : AppColors.textSecondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        ZStack {
                                            if selectedCategory == cat {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.15))
                                                    .matchedGeometryEffect(id: "CATEGORY_HIGHLIGHT", in: animation)
                                            }
                                        }
                                    )
                                    .contentShape(Capsule())
                                }
                                .buttonStyle(CategoryButtonStyle())
                            }
                        }
                        .padding(4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)
                    
                    // Favourites empty state
                    ScrollView {
                        if selectedCategory == "Favourites" && filteredVehicles.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "heart")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.textTertiary)
                                Text("No favourites yet")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Tap the heart icon on any vehicle to save it here.")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                            .padding(.horizontal, 32)
                            .transition(.opacity)
                        } else if filteredVehicles.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.textTertiary)
                                Text("No vehicles found")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Try adjusting your search or category filter.")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.top, 60)
                            .transition(.opacity)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredVehicles) { vehicle in
                                    NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                        vehicleRow(for: vehicle)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .transition(.opacity)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }


    @ViewBuilder
    private func vehicleRow(for vehicle: Vehicle) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: AppRadius.swatch)
                .fill(vehicle.thumbnailColor)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vehicle.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(vehicle.brand)
                        .font(AppFonts.bodyText)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // Category Badge
                        Text(vehicle.category)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                        
                        // Powertrain Badges
                        ForEach(vehicle.powertrainBadges, id: \.self) { badge in
                            Text(badge)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        // Availability Badges
                        if !vehicle.id.hasPrefix("defender") {
                            Text("AR Ready")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(4)
                            
                            Text("Virtual Garage")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.purple.opacity(0.8))
                                .cornerRadius(4)
                        } else {
                            Text("Specs Only")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            Spacer()
            
            Button(action: {
                var ids = bookmarkedIDs
                if ids.contains(vehicle.id) {
                    ids.remove(vehicle.id)
                } else {
                    ids.insert(vehicle.id)
                }
                bookmarkedRaw = ids.joined(separator: ",")
            }) {
                Image(systemName: bookmarkedIDs.contains(vehicle.id) ? "heart.fill" : "heart")
                    .foregroundColor(bookmarkedIDs.contains(vehicle.id) ? .red : AppColors.textTertiary)
                    .font(.system(size: 18))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)

            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    ContentView()
}

struct CategoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
