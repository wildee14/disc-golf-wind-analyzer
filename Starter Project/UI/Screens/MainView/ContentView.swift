import SwiftUI

struct ContentView: View {
    @StateObject private var appData = AppData()
    @StateObject private var locationManager = LocationDataManager()
    @StateObject private var weatherService = FreeWeatherService()
    @State private var showingDiscManager = false
    
    var body: some View {
        TabView {
            // Updated Discs tab with quick access
            DiscSelectionView(appData: appData, onManageDiscs: { showingDiscManager = true })
                .tabItem {
                    Image(systemName: "circle.grid.2x2")
                    Text("Discs")
                }
            
            ConditionsView(
                appData: appData,
                locationManager: locationManager,
                weatherService: weatherService
            )
            .tabItem {
                Image(systemName: "cloud.sun")
                Text("Conditions")
            }
            
            RecommendationView(appData: appData)
                .tabItem {
                    Image(systemName: "lightbulb")
                    Text("Recommend")
                }
        }
        .environmentObject(appData)
        .overlay(
            QuickConditionsOverlay(
                appData: appData,
                weatherService: weatherService
            )
        )
        .sheet(isPresented: $showingDiscManager) {
            DiscManagerView(appData: appData)
        }
        .task {
            // Initial weather load when app starts
            await loadWeatherIfAvailable()
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            // Reload weather when location permissions change
            if status == .authorizedWhenInUse {
                Task {
                    await loadWeatherIfAvailable()
                }
            }
        }
        .overlay(
            QuickConditionsOverlay(
                appData: appData,
                weatherService: weatherService
            )
        )
    }
    
    private func loadWeatherIfAvailable() async {
        if !locationManager.isUsingManualLocation,
           locationManager.authorizationStatus == .authorizedWhenInUse {
            await weatherService.fetchWeather(
                latitude: locationManager.latitude,
                longitude: locationManager.longitude
            )
        }
    }
}

// MARK: - Data Models (Updated with Equatable)


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
