//
//  CoursePreset.swift
//  Starter Project
//
//  Created by Matt Wilderson on 11/29/25.
//


import SwiftUI
import CoreLocation

struct CoursePreset: Identifiable, Codable {
    var id = UUID()
    let name: String
    let elevation: Double
    let commonWindPattern: String
    let typicalConditions: FlightCondition
}

class CoursePresetManager: ObservableObject {
    @Published var savedCourses: [CoursePreset] = []
    private let saveKey = "savedCourses"
    
    init() {
        loadCourses()
        createDefaultPresets()
    }
    
    func saveCourse(_ course: CoursePreset) {
        if let index = savedCourses.firstIndex(where: { $0.id == course.id }) {
            savedCourses[index] = course
        } else {
            savedCourses.append(course)
        }
        saveCourses()
    }
    
    func deleteCourse(_ course: CoursePreset) {
        savedCourses.removeAll { $0.id == course.id }
        saveCourses()
    }
    
    private func createDefaultPresets() {
        if savedCourses.isEmpty {
            let defaultCourses = [
                CoursePreset(
                    name: "Mountain Course",
                    elevation: 2500,
                    commonWindPattern: "Afternoon Uphill",
                    typicalConditions: FlightCondition(
                        windSpeed: 12,
                        windDirection: "Headwind",
                        temperature: 65,
                        elevation: 2500,
                        humidity: 40
                    )
                ),
                CoursePreset(
                    name: "Lakeside Park",
                    elevation: 800,
                    commonWindPattern: "Crosswind from Water",
                    typicalConditions: FlightCondition(
                        windSpeed: 8,
                        windDirection: "Crosswind Right",
                        temperature: 75,
                        elevation: 800,
                        humidity: 65
                    )
                ),
                CoursePreset(
                    name: "Forest Hills",
                    elevation: 1200,
                    commonWindPattern: "Protected & Calm",
                    typicalConditions: FlightCondition(
                        windSpeed: 3,
                        windDirection: "Calm",
                        temperature: 70,
                        elevation: 1200,
                        humidity: 60
                    )
                )
            ]
            savedCourses = defaultCourses
            saveCourses()
        }
    }
    
    private func saveCourses() {
        if let encoded = try? JSONEncoder().encode(savedCourses) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadCourses() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CoursePreset].self, from: data) {
            savedCourses = decoded
        }
    }
}
