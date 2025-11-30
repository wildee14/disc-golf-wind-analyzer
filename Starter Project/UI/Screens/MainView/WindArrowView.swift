//
//  WindArrowView.swift
//  Starter Project
//
//  Created by Matt Wilderson on 11/29/25.
//


import SwiftUI

struct WindArrowView: View {
    let windDirection: String
    let throwDirection: String
    let windSpeed: Double
    let size: CGFloat
    
    private var relativeWindAngle: Angle {
        let baseAngles: [String: Double] = [
            "North": 0, "Northeast": 45, "East": 90, "Southeast": 135,
            "South": 180, "Southwest": 225, "West": 270, "Northwest": 315
        ]
        
        let throwAngle = baseAngles[throwDirection] ?? 0
        let windAngle = baseAngles[windDirection] ?? 0
        
        // Calculate relative angle (wind direction relative to throw)
        let relativeAngle = (windAngle - throwAngle + 360).truncatingRemainder(dividingBy: 360)
        return Angle(degrees: relativeAngle)
    }
    
    private var arrowColor: Color {
        switch windSpeed {
        case 0..<5: return .green
        case 5..<10: return .yellow
        case 10..<15: return .orange
        default: return .red
        }
    }
    
    private var arrowLength: CGFloat {
        switch windSpeed {
        case 0..<5: return size * 0.3
        case 5..<10: return size * 0.5
        case 10..<15: return size * 0.7
        default: return size * 0.9
        }
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Compass marks
            ForEach(0..<8) { index in
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 8)
                    .offset(y: -size/2 + 4)
                    .rotationEffect(Angle(degrees: Double(index) * 45))
            }
            
            // Throw direction indicator (always up)
            Triangle()
                .fill(Color.blue)
                .frame(width: 8, height: 12)
                .offset(y: -size/2 + 6)
            
            // Wind arrow
            WindArrowShape()
                .fill(arrowColor)
                .frame(width: 6, height: arrowLength)
                .rotationEffect(relativeWindAngle)
                .overlay(
                    WindArrowShape()
                        .fill(arrowColor.opacity(0.8))
                        .frame(width: 4, height: arrowLength * 0.7)
                        .rotationEffect(relativeWindAngle)
                )
            
            // Center dot
            Circle()
                .fill(Color.gray)
                .frame(width: 6, height: 6)
        }
    }
}

struct WindArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct WindArrowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            WindArrowView(windDirection: "North", throwDirection: "North", windSpeed: 8, size: 120)
            WindArrowView(windDirection: "East", throwDirection: "North", windSpeed: 15, size: 120)
            WindArrowView(windDirection: "South", throwDirection: "North", windSpeed: 3, size: 120)
        }
        .padding()
    }
}