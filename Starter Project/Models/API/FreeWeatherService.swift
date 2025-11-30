//
//  FreeWeatherService.swift
//  Starter Project
//
//  Created by Matt Wilderson on 11/28/25.
//

import Foundation
import CoreLocation

class FreeWeatherService: ObservableObject {
    @Published var currentConditions: WeatherData?
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiKey = "api_key"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    func fetchWeather(latitude: Double, longitude: Double) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        let urlString = "\(baseURL)?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let weatherResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            
            await MainActor.run {
                currentConditions = WeatherData(from: weatherResponse)
                isLoading = false
                print("✅ Weather fetched successfully: \(weatherResponse.name) - \(weatherResponse.main.temp)°F")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch weather: \(error.localizedDescription)"
                isLoading = false
                print("❌ Weather fetch failed: \(error)")
            }
        }
    }
    
    // Add this function to apply live data to your app conditions
    func applyLiveDataToConditions() -> FlightCondition? {
        guard let weather = currentConditions else { return nil }
        
        // Convert wind direction from degrees to your app's direction format
        let windDirection = convertWindDirectionToAppFormat(weather.windDirection)
        
        return FlightCondition(
            windSpeed: weather.windSpeed,
            windDirection: windDirection,
            temperature: weather.temperature,
            elevation: 0, // You might want to keep this manual or use another API
            humidity: weather.humidity
        )
    }
    
    private func convertWindDirectionToAppFormat(_ degrees: Double?) -> String {
        guard let degrees = degrees else { return "Headwind" }
        
        // Convert degrees to cardinal direction, then to your app's format
        let cardinal = degreesToCardinal(degrees)
        
        switch cardinal {
        case "N", "NNE", "NNW": return "Headwind"
        case "S", "SSE", "SSW": return "Tailwind"
        case "E", "ENE", "ESE": return "Crosswind Right"
        case "W", "WNW", "WSW": return "Crosswind Left"
        default: return "Headwind"
        }
    }
    
    private func degreesToCardinal(_ degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25) / 22.5) % 16
        return directions[index]
    }
}

// MARK: - Data Models
struct OpenWeatherResponse: Codable {
    let main: MainWeather
    let wind: Wind
    let weather: [WeatherCondition]
    let name: String
}

struct MainWeather: Codable {
    let temp: Double
    let humidity: Double
}

struct Wind: Codable {
    let speed: Double
    let deg: Double?
}

struct WeatherCondition: Codable {
    let main: String
    let description: String
}

struct WeatherData {
    let temperature: Double
    let windSpeed: Double
    let windDirection: Double?
    let humidity: Double
    let condition: String
    let locationName: String
    
    init(from response: OpenWeatherResponse) {
        temperature = response.main.temp
        windSpeed = response.wind.speed
        windDirection = response.wind.deg
        humidity = response.main.humidity
        condition = response.weather.first?.main ?? "Unknown"
        locationName = response.name
    }
    
    // For manual entry fallback
    init(temperature: Double, windSpeed: Double, windDirection: Double?, humidity: Double, condition: String, locationName: String) {
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.humidity = humidity
        self.condition = condition
        self.locationName = locationName
    }
    
    // Add these helper properties for easy display
    var temperatureFormatted: String { "\(Int(temperature))°F" }
    var windSpeedFormatted: String { "\(Int(windSpeed)) mph" }
    var humidityFormatted: String { "\(Int(humidity))%" }
}
