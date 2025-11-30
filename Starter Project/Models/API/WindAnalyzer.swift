import Foundation

struct WindAnalyzer {
    
    static func analyzeWindEffect(windSpeed: Double, windDirection: String, throwDirection: String) -> (description: String, advice: String, stabilityAdjustment: Int, relativeWind: String) {
        
        let relativeWind = calculateRelativeWind(windDirection: windDirection, throwDirection: throwDirection)
        
        switch relativeWind {
        case "Headwind":
            let analysis = headwindAnalysis(windSpeed: windSpeed)
            return (analysis.description, analysis.advice, analysis.stabilityAdjustment, relativeWind)
        case "Tailwind":
            let analysis = tailwindAnalysis(windSpeed: windSpeed)
            return (analysis.description, analysis.advice, analysis.stabilityAdjustment, relativeWind)
        case "Crosswind Left":
            let analysis = crosswindLeftAnalysis(windSpeed: windSpeed)
            return (analysis.description, analysis.advice, analysis.stabilityAdjustment, relativeWind)
        case "Crosswind Right":
            let analysis = crosswindRightAnalysis(windSpeed: windSpeed)
            return (analysis.description, analysis.advice, analysis.stabilityAdjustment, relativeWind)
        default:
            return ("Calm Conditions", "Minimal wind effect. Throw your normal discs.", 0, relativeWind)
        }
    }
    
    static func calculateRelativeWind(windDirection: String, throwDirection: String) -> String {
        // Map compass directions to understand relative wind
        let directionMapping: [String: [String: String]] = [
            "North": [
                "Headwind": "South",      // Wind from South = Headwind when throwing North
                "Tailwind": "North",      // Wind from North = Tailwind when throwing North
                "Crosswind Left": "East", // Wind from East = Crosswind Left when throwing North
                "Crosswind Right": "West" // Wind from West = Crosswind Right when throwing North
            ],
            "South": [
                "Headwind": "North",      // Wind from North = Headwind when throwing South
                "Tailwind": "South",      // Wind from South = Tailwind when throwing South
                "Crosswind Left": "West", // Wind from West = Crosswind Left when throwing South
                "Crosswind Right": "East" // Wind from East = Crosswind Right when throwing South
            ],
            "East": [
                "Headwind": "West",       // Wind from West = Headwind when throwing East
                "Tailwind": "East",       // Wind from East = Tailwind when throwing East
                "Crosswind Left": "South", // Wind from South = Crosswind Left when throwing East
                "Crosswind Right": "North" // Wind from North = Crosswind Right when throwing East
            ],
            "West": [
                "Headwind": "East",       // Wind from East = Headwind when throwing West
                "Tailwind": "West",       // Wind from West = Tailwind when throwing West
                "Crosswind Left": "North", // Wind from North = Crosswind Left when throwing West
                "Crosswind Right": "South" // Wind from South = Crosswind Right when throwing West
            ]
        ]
        
        // For the current wind direction, find what type of wind it is relative to throw direction
        if let throwMap = directionMapping[throwDirection] {
            for (windType, comingFrom) in throwMap {
                if comingFrom == windDirection {
                    return windType
                }
            }
        }
        
        // Fallback - use direct mapping if no match found
        return windDirection
    }
    
    private static func headwindAnalysis(windSpeed: Double) -> (description: String, advice: String, stabilityAdjustment: Int) {
        switch windSpeed {
        case 0..<5:
            return ("Light Headwind", "Slight overstable tendency. Stick with your normal discs.", 1)
        case 5..<10:
            return ("Moderate Headwind", "Discs will act more understable. Add +1 to fade rating.", 2)
        case 10..<15:
            return ("Strong Headwind", "Significant understable effect. Use very overstable discs.", 3)
        default:
            return ("Extreme Headwind", "Discs will flip dramatically. Max overstable only.", 4)
        }
    }
    
    private static func tailwindAnalysis(windSpeed: Double) -> (description: String, advice: String, stabilityAdjustment: Int) {
        switch windSpeed {
        case 0..<5:
            return ("Light Tailwind", "Slight extra glide. Normal disc selection.", 0)
        case 5..<10:
            return ("Moderate Tailwind", "Extra distance potential. Can use more understable discs.", -1)
        case 10..<15:
            return ("Strong Tailwind", "Discs will act more overstable. Good for flip-up shots.", -2)
        default:
            return ("Extreme Tailwind", "Discs will fight to fade early. Use understable options.", -3)
        }
    }
    
    private static func crosswindLeftAnalysis(windSpeed: Double) -> (description: String, advice: String, stabilityAdjustment: Int) {
        switch windSpeed {
        case 0..<5:
            return ("Light Left Crosswind", "Minimal drift for RHBH. Normal selection.", 0)
        case 5..<10:
            return ("Moderate Left Crosswind", "RHBH will drift right. Slight overstable preference.", 1)
        case 10..<15:
            return ("Strong Left Crosswind", "Significant right drift for RHBH. Use overstable discs.", 2)
        default:
            return ("Extreme Left Crosswind", "Major right drift. Very overstable or forehand shots.", 3)
        }
    }
    
    private static func crosswindRightAnalysis(windSpeed: Double) -> (description: String, advice: String, stabilityAdjustment: Int) {
        switch windSpeed {
        case 0..<5:
            return ("Light Right Crosswind", "Minimal drift for RHBH. Normal selection.", 0)
        case 5..<10:
            return ("Moderate Right Crosswind", "RHBH will fight left. Slight understable preference.", -1)
        case 10..<15:
            return ("Strong Right Crosswind", "Discs want to turn over. Use stable to understable.", -2)
        default:
            return ("Extreme Right Crosswind", "High turnover risk. Very understable or flex lines.", -3)
        }
    }
    
    static func getWindEffectExplanation(windDirection: String, windSpeed: Double, throwDirection: String) -> String {
        let analysis = analyzeWindEffect(windSpeed: windSpeed, windDirection: windDirection, throwDirection: throwDirection)
        
        switch analysis.relativeWind {
        case "Headwind":
            return "Throwing \(throwDirection) into \(windDirection) wind = HEADWIND. Reduces lift - discs act MORE UNDERSTABLE. \(analysis.advice)"
        case "Tailwind":
            return "Throwing \(throwDirection) with \(windDirection) wind = TAILWIND. Increases lift - discs act MORE OVERSTABLE. \(analysis.advice)"
        case "Crosswind Left":
            return "Throwing \(throwDirection) with \(windDirection) wind = LEFT CROSSWIND. Pushes RHBH shots RIGHT. \(analysis.advice)"
        case "Crosswind Right":
            return "Throwing \(throwDirection) with \(windDirection) wind = RIGHT CROSSWIND. Pushes RHBH shots LEFT. \(analysis.advice)"
        default:
            return "Throwing \(throwDirection) - calm conditions with minimal wind effects."
        }
    }
    
    static func getStabilityAdjustment(windSpeed: Double, windDirection: String, throwDirection: String) -> Int {
        let analysis = analyzeWindEffect(windSpeed: windSpeed, windDirection: windDirection, throwDirection: throwDirection)
        return analysis.stabilityAdjustment
    }
}
