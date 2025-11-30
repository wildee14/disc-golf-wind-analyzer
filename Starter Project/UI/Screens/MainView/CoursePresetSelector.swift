//
//  CoursePresetSelector.swift
//  Starter Project
//
//  Created by Matt Wilderson on 11/29/25.
//


import SwiftUI

struct CoursePresetSelector: View {
    @ObservedObject var presetManager: CoursePresetManager
    @ObservedObject var appData: AppData
    @State private var showingAddCourse = false
    @State private var newCourseName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Course Presets")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingAddCourse = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presetManager.savedCourses) { course in
                        CoursePresetButton(
                            course: course,
                            onSelect: { applyCoursePreset(course) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingAddCourse) {
            addCourseSheet
        }
    }
    
    private func applyCoursePreset(_ course: CoursePreset) {
        appData.currentConditions = course.typicalConditions
    }
    
    private var addCourseSheet: some View {
        NavigationView {
            Form {
                TextField("Course Name", text: $newCourseName)
                
                Section(header: Text("Current conditions will be saved")) {
                    Text("Elevation: \(Int(appData.currentConditions.elevation)) ft")
                    Text("Wind: \(appData.currentConditions.windDirection)")
                    Text("Temp: \(Int(appData.currentConditions.temperature))°F")
                }
                
                Button("Save Course Preset") {
                    let newCourse = CoursePreset(
                        name: newCourseName,
                        elevation: appData.currentConditions.elevation,
                        commonWindPattern: appData.currentConditions.windDirection,
                        typicalConditions: appData.currentConditions
                    )
                    presetManager.saveCourse(newCourse)
                    showingAddCourse = false
                    newCourseName = ""
                }
                .disabled(newCourseName.isEmpty)
            }
            .navigationTitle("Add Course")
            .navigationBarItems(trailing: Button("Cancel") {
                showingAddCourse = false
            })
        }
    }
}

struct CoursePresetButton: View {
    let course: CoursePreset
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("\(Int(course.elevation))ft")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(course.commonWindPattern)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
