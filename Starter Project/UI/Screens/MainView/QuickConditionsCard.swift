import SwiftUI

struct QuickConditionsOverlay: View {
    @ObservedObject var appData: AppData
    @ObservedObject var weatherService: FreeWeatherService
    @State private var showDetailedView = false
    @State private var throwDirection = "North" // Add throwDirection here
    
    private var conditionImpact: (description: String, color: Color) {
        let conditions = appData.currentConditions
        let score = conditions.windSpeed + abs(conditions.temperature - 70) / 10 + abs(conditions.elevation) / 1000
        
        switch score {
        case 0..<5: return ("Ideal Conditions", .green)
        case 5..<10: return ("Moderate Impact", .yellow)
        case 10..<15: return ("Challenging Conditions", .orange)
        default: return ("Extreme Impact", .red)
        }
    }
    
    private var windAnalysis: String {
        let analysis = WindAnalyzer.analyzeWindEffect(
            windSpeed: appData.currentConditions.windSpeed,
            windDirection: appData.currentConditions.windDirection,
            throwDirection: throwDirection // Use the local throwDirection
        )
        return "\(analysis.relativeWind): \(analysis.advice)"
    }
    
    private var topRecommendedDisc: String {
        let recommendations = calculateQuickRecommendations()
        return recommendations.first?.name ?? "Stable Mid-range"
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                QuickConditionsCard(
                    temperature: appData.currentConditions.temperature,
                    windSpeed: appData.currentConditions.windSpeed,
                    windDirection: appData.currentConditions.windDirection,
                    topDisc: topRecommendedDisc,
                    conditionImpact: conditionImpact.description,
                    impactColor: conditionImpact.color,
                    onTap: {
                        showDetailedView = true
                    },
                    windAnalysis: windAnalysis
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showDetailedView) {
            NavigationView {
                ConditionsView(
                    appData: appData,
                    locationManager: LocationDataManager(),
                    weatherService: weatherService
                )
            }
        }
    }
    
    private func calculateQuickRecommendations() -> [Disc] {
        var scoredDiscs: [(disc: Disc, score: Int)] = []
        let conditions = appData.currentConditions
        
        // Get stability adjustment based on throw direction
        let stabilityAdjustment = WindAnalyzer.getStabilityAdjustment(
            windSpeed: conditions.windSpeed,
            windDirection: conditions.windDirection,
            throwDirection: throwDirection // Now this works!
        )
        
        for disc in appData.myDiscs {
            var score = 0
            
            // Base score from wind analysis
            score += calculateWindScore(disc: disc, conditions: conditions, stabilityAdjustment: stabilityAdjustment)
            
            // Quick temperature adjustment
            if conditions.temperature < 50 {
                if disc.stability.contains("Understable") {
                    score += 1  // Help counteract cold-weather overstability
                }
            }
            
            scoredDiscs.append((disc, score))
        }
        
        return scoredDiscs.sorted { $0.score > $1.score }.map { $0.disc }
    }
    
    private func calculateWindScore(disc: Disc, conditions: FlightCondition, stabilityAdjustment: Int) -> Int {
        var score = 0
        
        // Apply stability adjustment from wind analysis
        let effectiveStability = calculateEffectiveStability(disc: disc, adjustment: stabilityAdjustment)
        
        // Score based on effective stability needed
        switch effectiveStability {
        case "Very Overstable":
            score += calculateStabilityMatch(disc: disc, targetStability: "Very Overstable")
        case "Overstable":
            score += calculateStabilityMatch(disc: disc, targetStability: "Overstable")
        case "Stable":
            score += calculateStabilityMatch(disc: disc, targetStability: "Stable")
        case "Understable":
            score += calculateStabilityMatch(disc: disc, targetStability: "Understable")
        case "Very Understable":
            score += calculateStabilityMatch(disc: disc, targetStability: "Very Understable")
        default:
            score += 0
        }
        
        return score
    }
    
    private func calculateStabilityMatch(disc: Disc, targetStability: String) -> Int {
        let stabilityOrder = ["Very Understable", "Understable", "Stable", "Overstable", "Very Overstable"]
        
        guard let discIndex = stabilityOrder.firstIndex(of: disc.stability),
              let targetIndex = stabilityOrder.firstIndex(of: targetStability) else {
            return 0
        }
        
        let distance = abs(discIndex - targetIndex)
        return max(0, 3 - distance) // Higher score for closer matches
    }
    
    private func calculateEffectiveStability(disc: Disc, adjustment: Int) -> String {
        let stabilityOrder = ["Very Understable", "Understable", "Stable", "Overstable", "Very Overstable"]
        
        guard let currentIndex = stabilityOrder.firstIndex(of: disc.stability) else {
            return disc.stability
        }
        
        let newIndex = max(0, min(stabilityOrder.count - 1, currentIndex + adjustment))
        return stabilityOrder[newIndex]
    }
}

struct QuickConditionsCard: View {
    let temperature: Double
    let windSpeed: Double
    let windDirection: String
    let topDisc: String
    let conditionImpact: String
    let impactColor: Color
    let onTap: () -> Void
    let windAnalysis: String
    
    // Computed properties for quick display
    private var temperatureFormatted: String { "\(Int(temperature))°F" }
    private var windFormatted: String { "\(Int(windSpeed)) mph" }
    
    // Wind direction emoji
    private var windDirectionEmoji: String {
        switch windDirection {
        case "Headwind": return "⬇️"
        case "Tailwind": return "⬆️"
        case "Crosswind Left": return "⬅️"
        case "Crosswind Right": return "➡️"
        default: return "🌀"
        }
    }
    
    // Condition impact icon
    private var conditionImpactIcon: String {
        switch conditionImpact {
        case "Ideal Conditions": return "⭐️"
        case "Moderate Impact": return "⚠️"
        case "Challenging Conditions": return "🎯"
        case "Extreme Impact": return "🔥"
        default: return "📊"
        }
    }
    
    // Wind effect color
    private var windEffectColor: Color {
        switch conditionImpact {
        case "Ideal Conditions": return .green
        case "Moderate Impact": return .yellow
        case "Challenging Conditions": return .orange
        case "Extreme Impact": return .red
        default: return .gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with quick stats
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Impact level
                        HStack(spacing: 6) {
                            Text(conditionImpactIcon)
                            Text(conditionImpact)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(impactColor)
                        }
                        
                        // Quick conditions
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "thermometer")
                                    .font(.system(size: 12))
                                Text(temperatureFormatted)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "wind")
                                    .font(.system(size: 12))
                                Text(windFormatted)
                                    .font(.system(size: 14, weight: .medium))
                                Text(windDirectionEmoji)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Quick action indicator
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .opacity(0.7)
                }
                
                // Wind Analysis
                Text(windAnalysis)
                    .font(.system(size: 12))
                    .foregroundColor(windEffectColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Top recommendation
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("Smart Throw:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(topDisc)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickConditionsOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            QuickConditionsOverlay(
                appData: AppData(),
                weatherService: FreeWeatherService()
            )
        }
    }
}
