import SwiftUI
struct RecommendationView: View {
    @ObservedObject var appData: AppData
    
    var recommendedDiscs: [Disc] {
        return calculateRecommendations()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Conditions Summary
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Conditions")
                        .font(.headline)
                    Text("\(Int(appData.currentConditions.windSpeed)) mph \(appData.currentConditions.windDirection) • \(Int(appData.currentConditions.temperature))°F")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Recommended Discs List
                List(recommendedDiscs, id: \.name) { disc in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(disc.name)
                                .font(.headline)
                            Spacer()
                            Text(disc.stability)
                                .font(.caption)
                                .padding(6)
                                .background(stabilityColor(disc.stability))
                                .cornerRadius(4)
                        }
                        
                        Text(disc.brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Speed: \(disc.speed)")
                            Text("Glide: \(disc.glide)")
                            Text("Turn: \(disc.turn)")
                            Text("Fade: \(disc.fade)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Disc Recommendations")
        }
    }
    
    // MARK: - Recommendation Logic
    private func calculateRecommendations() -> [Disc] {
        var scoredDiscs: [(disc: Disc, score: Int)] = []
        let conditions = appData.currentConditions
        
        for disc in appData.myDiscs {
            var score = 0
            
            // Wind-based recommendations
            if conditions.windSpeed > 10 {
                // High wind - prefer overstable discs
                if disc.stability.contains("Overstable") || disc.fade >= 3 {
                    score += 3
                }
                if disc.stability.contains("Understable") {
                    score -= 2
                }
            } else if conditions.windSpeed < 5 {
                // Light wind - understable discs work well
                if disc.stability.contains("Understable") {
                    score += 2
                }
            }
            
            // Wind direction logic
            if conditions.windDirection == "Headwind" {
                // Headwind - need more overstable
                if disc.fade >= 2 || disc.turn >= 0 {
                    score += 2
                }
            } else if conditions.windDirection == "Tailwind" {
                // Tailwind - can use understable
                if disc.turn <= -2 {
                    score += 1
                }
            }
            
            // Temperature effects (colder = more overstable)
            if conditions.temperature < 50 {
                if disc.stability.contains("Understable") {
                    score += 1  // Help counteract cold-weather overstability
                }
            }
            
            scoredDiscs.append((disc, score))
        }
        
        // Sort by score descending and return top discs
        return scoredDiscs.sorted { $0.score > $1.score }.map { $0.disc }
    }
    
    private func stabilityColor(_ stability: String) -> Color {
        switch stability {
        case "Understable":
            return .blue.opacity(0.3)
        case "Stable":
            return .green.opacity(0.3)
        case "Overstable":
            return .orange.opacity(0.3)
        case "Very Overstable":
            return .red.opacity(0.3)
        default:
            return .gray.opacity(0.3)
        }
    }
}
