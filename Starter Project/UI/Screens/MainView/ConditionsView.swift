import SwiftUI
import CoreLocation

struct ConditionsView: View {
    // MARK: - State Properties for User Input
    @State private var windSpeed: Double = 5
    @State private var windDirection: String = "Headwind"
    @State private var temperature: Double = 70
    @State private var elevation: Double = 500
    @State private var humidity: Double = 60
    @State private var precipitation: Double = 0
    @State private var airDensity: Double = 1.225
    @State private var showAdvanced: Bool = false
    @State private var savedPresets: [String: FlightCondition] = [:]
    @State private var showingSavePreset = false
    @State private var presetName = ""
    
    // MARK: - Live Data Services
    @ObservedObject var appData: AppData
    @ObservedObject var locationManager: LocationDataManager
    @ObservedObject var weatherService: FreeWeatherService
    
    @State private var showingLocationPicker = false
    @State private var isUsingLiveData = false
    
    // MARK: - Course Presets
    @StateObject private var presetManager = CoursePresetManager()
    @StateObject private var compassManager = CompassManager()

    @State private var throwDirection = "North" // Default throw direction
    
    // MARK: - Available Options
    let windDirections = ["Headwind", "Tailwind", "Crosswind Left", "Crosswind Right", "Calm"]
    let precipitationTypes = ["None", "Light Rain", "Heavy Rain", "Fog/Mist", "Snow"]
    
    let manualCities = [
        "Austin, TX", "Portland, OR", "Charlotte, NC",
        "Denver, CO", "Seattle, WA", "Boston, MA"
    ]
    
    // MARK: - Computed Properties
    private var conditionSeverity: (color: Color, description: String) {
        let score = windSpeed + abs(temperature - 70) / 10 + abs(elevation) / 1000
        switch score {
        case 0..<5: return (.green, "Ideal Conditions")
        case 5..<10: return (.yellow, "Moderate Impact")
        case 10..<15: return (.orange, "Challenging Conditions")
        default: return (.red, "Extreme Impact")
        }
    }
    
    private var calculatedAirDensity: Double {
        // Simplified air density calculation based on temperature and elevation
        let baseDensity = 1.225 // kg/m³ at sea level, 15°C
        let tempEffect = 0.004 * (70 - temperature) // Density increases as temp decreases
        let elevationEffect = -0.0001 * elevation // Density decreases with elevation
        return max(1.0, baseDensity + tempEffect + elevationEffect)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // MARK: - Location & Live Data Header
                    locationHeader
                    
                    compassWindCard
                    
                    // MARK: - Course Presets
                    CoursePresetSelector(
                        presetManager: presetManager,
                        appData: appData
                    )
                    
                    // MARK: - Wind Intelligence Card
                    windIntelligenceCard
                    
                    // MARK: - Live Weather Data Card
                    liveWeatherCard
                    
                    // MARK: - Conditions Summary Card
                    conditionsSummaryCard
                    
                    // MARK: - Manual Conditions Card
                    manualConditionsCard
                    
                    // MARK: - Advanced Settings
                    if showAdvanced {
                        advancedSettingsCard
                    }
                    
                    // MARK: - Quick Presets
                    quickPresetsCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Flight Conditions")
            .navigationBarItems(
                trailing: HStack {
                    Button(action: { showAdvanced.toggle() }) {
                        Image(systemName: showAdvanced ? "gearshape.fill" : "gearshape")
                    }
                    
                    Menu {
                        Button("Save Current Preset") {
                            showingSavePreset = true
                        }
                        Button("Reset to Default") {
                            resetToDefaults()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            )
            .sheet(isPresented: $showingSavePreset) {
                savePresetSheet
            }
            .sheet(isPresented: $showingLocationPicker) {
                locationPickerSheet
            }
            .onAppear {
               compassManager.startUpdatingHeading { direction in
                   throwDirection = direction
               }
            }
            .onDisappear {
               compassManager.stopUpdatingHeading()
            }
            .onChange(of: appData.currentConditions) { _ in
                // Update manual inputs when app data changes
                syncWithAppData()
            }
        }
    }
    
    // MARK: - Component Views
    private var compassWindCard: some View {
           CardView(title: "Wind Visualization", icon: "location.north") {
               VStack(spacing: 20) {
                   // Compass and wind arrow
                   HStack {
                       VStack {
                           WindArrowView(
                               windDirection: windDirection,
                               throwDirection: throwDirection,
                               windSpeed: windSpeed,
                               size: 120
                           )
                           
                           Text("Throw: \(throwDirection)")
                               .font(.caption)
                               .foregroundColor(.secondary)
                       }
                       
                       VStack(alignment: .leading, spacing: 12) {
                           if compassManager.isAvailable {
                               HStack {
                                   Image(systemName: "location.north.fill")
                                       .foregroundColor(.blue)
                                   Text("Using Compass")
                                       .font(.caption)
                                       .foregroundColor(.green)
                               }
                           }
                           
                           Text("Wind: \(windDirection)")
                               .font(.headline)
                           
                           Text("\(Int(windSpeed)) mph")
                               .font(.title2)
                               .fontWeight(.bold)
                               .foregroundColor(windEffectColor(windSpeed))
                           
                           Button("Reset to North") {
                               throwDirection = "North"
                           }
                           .font(.caption)
                           .disabled(throwDirection == "North")
                       }
                       .padding(.leading, 20)
                   }
                   
                   // Quick direction buttons
                   ScrollView(.horizontal, showsIndicators: false) {
                       HStack(spacing: 8) {
                           ForEach(["North", "South", "East", "West", "Northeast", "Northwest", "Southeast", "Southwest"], id: \.self) { direction in
                               Button(action: {
                                   throwDirection = direction
                               }) {
                                   Text(direction)
                                       .font(.system(size: 14, weight: .medium))
                                       .padding(.horizontal, 12)
                                       .padding(.vertical, 6)
                                       .background(throwDirection == direction ? Color.blue : Color.gray.opacity(0.2))
                                       .foregroundColor(throwDirection == direction ? .white : .primary)
                                       .cornerRadius(8)
                               }
                           }
                       }
                   }
               }
           }
       }
    
    private var locationHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(locationManager.manualLocationName)
                    .font(.headline)
                
                if locationManager.isUsingManualLocation {
                    Text("Tap to select city")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Using your location")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button(action: {
                if locationManager.isUsingManualLocation {
                    showingLocationPicker = true
                } else {
                    loadLiveWeather()
                }
            }) {
                Image(systemName: locationManager.isUsingManualLocation ? "location.slash" : "location.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onTapGesture {
            showingLocationPicker = true
        }
    }
    
    private var windIntelligenceCard: some View {
        CardView(title: "Wind Intelligence", icon: "brain.head.profile") {
            VStack(alignment: .leading, spacing: 12) {
                let windAnalysis = WindAnalyzer.analyzeWindEffect(
                    windSpeed: windSpeed,
                    windDirection: windDirection,
                    throwDirection: throwDirection
                )
                
                // Relative wind display
                HStack {
                    VStack(alignment: .leading) {
                        Text("Your Throw: \(throwDirection)")
                            .font(.headline)
                        Text("Wind: \(windDirection)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(windAnalysis.relativeWind)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(windEffectColor(windSpeed))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(windEffectColor(windSpeed).opacity(0.2))
                        .cornerRadius(8)
                }
                
                Text(windAnalysis.description)
                    .font(.headline)
                    .foregroundColor(windEffectColor(windSpeed))
                
                Text(windAnalysis.advice)
                    .font(.body)
                    .foregroundColor(.primary)
                
                // Stability adjustment indicator
                if windAnalysis.stabilityAdjustment != 0 {
                    HStack {
                        Image(systemName: windAnalysis.stabilityAdjustment > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(windAnalysis.stabilityAdjustment > 0 ? .orange : .blue)
                        
                        Text("Stability Adjustment: \(windAnalysis.stabilityAdjustment > 0 ? "+" : "")\(windAnalysis.stabilityAdjustment)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(windAnalysis.stabilityAdjustment > 0 ? "(More Overstable)" : "(More Understable)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Throw direction picker
                VStack(alignment: .leading) {
                    Text("Your Throw Direction")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Throw Direction", selection: $throwDirection) {
                        Text("North").tag("North")
                        Text("South").tag("South")
                        Text("East").tag("East")
                        Text("West").tag("West")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: throwDirection) { _ in
                        // This will trigger recomputation of recommendations
                        updateAppData()
                    }
                }
                
                // Wind effect explanation
                Text(WindAnalyzer.getWindEffectExplanation(
                    windDirection: windDirection,
                    windSpeed: windSpeed,
                    throwDirection: throwDirection
                ))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
    
    private var liveWeatherCard: some View {
        CardView(title: "Live Weather Data", icon: "cloud.sun") {
            VStack(spacing: 16) {
                if weatherService.isLoading {
                    ProgressView("Fetching weather...")
                        .frame(maxWidth: .infinity)
                } else if let error = weatherService.error {
                    VStack(spacing: 8) {
                        Text("Weather unavailable")
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("Try Again") {
                            loadLiveWeather()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                } else if let weather = weatherService.currentConditions {
                    VStack(spacing: 12) {
                        Text("📍 \(weather.locationName)")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            liveWeatherPill(icon: "thermometer", value: weather.temperatureFormatted)
                            liveWeatherPill(icon: "wind", value: weather.windSpeedFormatted)
                            liveWeatherPill(icon: "humidity", value: weather.humidityFormatted)
                        }
                        
                        Text("☁ \(weather.condition)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Apply Live Data to Conditions") {
                            applyLiveWeatherData(weather)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Text("Enable location or select a city")
                            .foregroundColor(.secondary)
                        Button("Get Live Weather") {
                            loadLiveWeather()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var conditionsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Condition Impact")
                        .font(.headline)
                    Text(conditionSeverity.description)
                        .font(.subheadline)
                        .foregroundColor(conditionSeverity.color)
                }
                
                Spacer()
                
                // Wind direction indicator
                VStack {
                    Image(systemName: windDirectionIcon)
                        .font(.title2)
                        .rotationEffect(windDirectionRotation)
                    Text(windDirection)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 16) {
                conditionPill(icon: "thermometer", value: "\(Int(temperature))°F")
                conditionPill(icon: "humidity", value: "\(Int(humidity))%")
                conditionPill(icon: "mountain.2", value: "\(Int(elevation))ft")
                conditionPill(icon: "wind", value: "\(Int(windSpeed))mph")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var manualConditionsCard: some View {
        CardView(title: "Manual Conditions", icon: "slider.horizontal.3") {
            VStack(spacing: 20) {
                // Wind Speed with visual indicator
                VStack(alignment: .leading) {
                    HStack {
                        Text("Wind Speed")
                        Spacer()
                        Text("\(Int(windSpeed)) mph")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    
                    Slider(value: $windSpeed, in: 0...30, step: 1)
                        .onChange(of: windSpeed) { _ in
                            updateAppData()
                        }
                    
                    // Visual wind indicator
                    HStack {
                        ForEach(0..<6) { index in
                            Rectangle()
                                .fill(index < Int(windSpeed / 5) ? windColor : Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                        }
                    }
                }
                
                // Wind Direction Picker with visual indicators
                VStack(alignment: .leading) {
                    Text("Wind Direction")
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(windDirections, id: \.self) { direction in
                            Button(action: {
                                windDirection = direction
                                updateAppData()
                            }) {
                                Text(direction)
                                    .font(.caption)
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(windDirection == direction ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(windDirection == direction ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                labeledSlider(
                    title: "Temperature",
                    value: $temperature,
                    range: 30...110,
                    unit: "°F",
                    icon: temperature > 80 ? "sun.max.fill" : temperature < 50 ? "snowflake" : "cloud.sun"
                )
                
                labeledSlider(
                    title: "Elevation",
                    value: $elevation,
                    range: -500...8000,
                    unit: "ft",
                    icon: "mountain.2"
                )
                
                labeledSlider(
                    title: "Humidity",
                    value: $humidity,
                    range: 0...100,
                    unit: "%",
                    icon: "humidity"
                )
            }
        }
    }
    
    private var advancedSettingsCard: some View {
        CardView(title: "Advanced", icon: "chart.line.uptrend.xyaxis") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Air Density: \(calculatedAirDensity, specifier: "%.3f") kg/m³")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Text("Density Altitude: \(calculateDensityAltitude(), specifier: "%.0f") ft")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Text("Higher air density makes discs more stable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var quickPresetsCard: some View {
        CardView(title: "Quick Presets", icon: "bookmark") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    presetButton("Ideal", icon: "star", color: .green) {
                        setIdealConditions()
                    }
                    
                    presetButton("Windy", icon: "wind", color: .blue) {
                        setWindyConditions()
                    }
                    
                    presetButton("Mountain", icon: "mountain.2", color: .orange) {
                        setMountainConditions()
                    }
                    
                    presetButton("Cold", icon: "snowflake", color: .purple) {
                        setColdConditions()
                    }
                }
            }
        }
    }
    
    private var savePresetSheet: some View {
        NavigationView {
            Form {
                TextField("Preset Name", text: $presetName)
                
                Button("Save") {
                    saveCurrentPreset()
                    showingSavePreset = false
                    presetName = ""
                }
                .disabled(presetName.isEmpty)
            }
            .navigationTitle("Save Preset")
            .navigationBarItems(trailing: Button("Cancel") {
                showingSavePreset = false
            })
        }
    }
    
    private var locationPickerSheet: some View {
        NavigationView {
            List(manualCities, id: \.self) { city in
                Button(city) {
                    locationManager.setManualLocation(name: city)
                    // Simulate weather for manual city
                    simulateWeatherForCity(city)
                    showingLocationPicker = false
                }
            }
            .navigationTitle("Select City")
            .navigationBarItems(trailing: Button("Cancel") {
                showingLocationPicker = false
            })
        }
    }
    
    // MARK: - Helper Views
    
    private func conditionPill(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func liveWeatherPill(icon: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func labeledSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, icon: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text("\(Int(value.wrappedValue))\(unit)")
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            
            Slider(value: value, in: range, step: range.upperBound / 100)
                .onChange(of: value.wrappedValue) { _ in
                    updateAppData()
                }
        }
    }
    
    private func presetButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
    }
    
    // MARK: - Computed Values
    
    private var windDirectionIcon: String {
        switch windDirection {
        case "Headwind": return "arrow.down"
        case "Tailwind": return "arrow.up"
        case "Crosswind Left": return "arrow.left"
        case "Crosswind Right": return "arrow.right"
        default: return "circle"
        }
    }
    
    private var windDirectionRotation: Angle {
        switch windDirection {
        case "Headwind": return .degrees(0)
        case "Tailwind": return .degrees(180)
        case "Crosswind Left": return .degrees(90)
        case "Crosswind Right": return .degrees(270)
        default: return .degrees(0)
        }
    }
    
    private var windColor: Color {
        switch windSpeed {
        case 0..<5: return .green
        case 5..<15: return .yellow
        case 15..<25: return .orange
        default: return .red
        }
    }
    
    private func windEffectColor(_ windSpeed: Double) -> Color {
        switch windSpeed {
        case 0..<5: return .green
        case 5..<10: return .yellow
        case 10..<15: return .orange
        default: return .red
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateDensityAltitude() -> Double {
        // Simplified density altitude calculation
        return elevation + (temperature - 70) * 100
    }
    
    private func loadLiveWeather() {
        Task {
            if !locationManager.isUsingManualLocation,
               locationManager.authorizationStatus == .authorizedWhenInUse {
                await weatherService.fetchWeather(
                    latitude: locationManager.latitude,
                    longitude: locationManager.longitude
                )
            } else if locationManager.isUsingManualLocation {
                // For manual cities, we'd need to geocode first
                // For now, just show a message
                print("Manual city selected - would need geocoding for live weather")
            }
        }
    }
    
    private func applyLiveWeatherData(_ weather: WeatherData) {
        // Update manual inputs with live weather data
        windSpeed = weather.windSpeed
        temperature = weather.temperature
        humidity = weather.humidity
        
        // Convert cardinal direction back to your app's wind direction format
        let cardinalToAppDirection: [String: String] = [
            "N": "Headwind", "S": "Tailwind", "E": "Crosswind Right",
            "W": "Crosswind Left", "NE": "Crosswind Right", "NW": "Crosswind Left",
            "SE": "Crosswind Right", "SW": "Crosswind Left"
        ]
        
        if let degrees = weather.windDirection {
            let cardinal = degreesToCardinal(degrees)
            windDirection = cardinalToAppDirection[cardinal] ?? "Headwind"
        }
        
        // Update app data
        updateAppData()
        isUsingLiveData = true
    }
    
    private func simulateWeatherForCity(_ city: String) {
        // Simple simulation - in real app you'd geocode and fetch actual weather
        let simulatedWeather = WeatherData(
            temperature: 72.0,
            windSpeed: 8.0,
            windDirection: 180.0,
            humidity: 65.0,
            condition: "Partly Cloudy",
            locationName: city
        )
        weatherService.currentConditions = simulatedWeather
    }
    
    private func degreesToCardinal(_ degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25) / 22.5) % 16
        return directions[index]
    }
    
    private func syncWithAppData() {
        // Sync manual inputs with app data
        windSpeed = appData.currentConditions.windSpeed
        windDirection = appData.currentConditions.windDirection
        temperature = appData.currentConditions.temperature
        elevation = appData.currentConditions.elevation
        humidity = appData.currentConditions.humidity
    }
    
    private func updateAppData() {
        // Update app data with current manual inputs
        appData.currentConditions = FlightCondition(
            windSpeed: windSpeed,
            windDirection: windDirection,
            temperature: temperature,
            elevation: elevation,
            humidity: humidity
        )
    }
    
    private func setIdealConditions() {
        windSpeed = 3
        windDirection = "Calm"
        temperature = 75
        humidity = 50
        elevation = 500
        precipitation = 0
        isUsingLiveData = false
        updateAppData()
    }
    
    private func setWindyConditions() {
        windSpeed = 18
        windDirection = "Headwind"
        temperature = 65
        humidity = 40
        isUsingLiveData = false
        updateAppData()
    }
    
    private func setMountainConditions() {
        elevation = 3500
        temperature = 60
        humidity = 30
        windSpeed = 8
        isUsingLiveData = false
        updateAppData()
    }
    
    private func setColdConditions() {
        temperature = 35
        humidity = 70
        windSpeed = 5
        precipitation = 20
        isUsingLiveData = false
        updateAppData()
    }
    
    private func resetToDefaults() {
        windSpeed = 5
        windDirection = "Headwind"
        temperature = 70
        elevation = 500
        humidity = 60
        precipitation = 0
        showAdvanced = false
        isUsingLiveData = false
        updateAppData()
    }
    
    private func saveCurrentPreset() {
        let condition = FlightCondition(
            windSpeed: windSpeed,
            windDirection: windDirection,
            temperature: temperature,
            elevation: elevation,
            humidity: humidity
        )
        savedPresets[presetName] = condition
    }
}

// MARK: - Supporting Views

struct CardView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

struct ConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        ConditionsView(
            appData: AppData(),
            locationManager: LocationDataManager(),
            weatherService: FreeWeatherService()
        )
    }
}
