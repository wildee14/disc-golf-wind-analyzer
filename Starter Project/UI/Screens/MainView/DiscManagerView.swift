//
//  DiscManagerView.swift
//  Starter Project
//
//  Created by Matt Wilderson on 11/29/25.
//


import SwiftUI

struct DiscManagerView: View {
    @ObservedObject var appData: AppData
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddDisc = false
    @State private var searchText = ""
    @State private var editMode: EditMode = .inactive
    
    var filteredDiscs: [Disc] {
        if searchText.isEmpty {
            return appData.myDiscs
        } else {
            return appData.myDiscs.filter { disc in
                disc.name.localizedCaseInsensitiveContains(searchText) ||
                disc.brand.localizedCaseInsensitiveContains(searchText) ||
                disc.stability.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Quick add button
                HStack {
                    TextField("Search discs...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: { showingAddDisc = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                List {
                    ForEach(filteredDiscs, id: \.name) { disc in
                        DiscRow(disc: disc)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteDisc(disc)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    duplicateDisc(disc)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                    }
                    .onMove(perform: moveDiscs)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("My Discs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAddDisc) {
                AddDiscView(appData: appData)
            }
        }
    }
    
    private func deleteDisc(_ disc: Disc) {
        if let index = appData.myDiscs.firstIndex(where: { $0.name == disc.name }) {
            appData.myDiscs.remove(at: index)
        }
    }
    
    private func duplicateDisc(_ disc: Disc) {
        let newDisc = Disc(
            name: "\(disc.name) Copy",
            brand: disc.brand,
            speed: disc.speed,
            glide: disc.glide,
            turn: disc.turn,
            fade: disc.fade,
            stability: disc.stability
        )
        appData.myDiscs.append(newDisc)
    }
    
    private func moveDiscs(from source: IndexSet, to destination: Int) {
        appData.myDiscs.move(fromOffsets: source, toOffset: destination)
    }
}

struct DiscRow: View {
    let disc: Disc
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(disc.name)
                    .font(.headline)
                
                Spacer()
                
                Text(disc.stability)
                    .font(.caption)
                    .padding(4)
                    .background(stabilityColor(disc.stability))
                    .cornerRadius(4)
            }
            
            Text(disc.brand)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                FlightNumberPill(label: "Speed", value: disc.speed)
                FlightNumberPill(label: "Glide", value: disc.glide)
                FlightNumberPill(label: "Turn", value: disc.turn)
                FlightNumberPill(label: "Fade", value: disc.fade)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func stabilityColor(_ stability: String) -> Color {
        switch stability {
        case "Very Understable": return .purple.opacity(0.3)
        case "Understable": return .blue.opacity(0.3)
        case "Stable": return .green.opacity(0.3)
        case "Overstable": return .orange.opacity(0.3)
        case "Very Overstable": return .red.opacity(0.3)
        default: return .gray.opacity(0.3)
        }
    }
}

struct FlightNumberPill: View {
    let label: String
    let value: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(width: 40)
    }
}

struct AddDiscView: View {
    @ObservedObject var appData: AppData
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var brand = ""
    @State private var speed = 5
    @State private var glide = 5
    @State private var turn = 0
    @State private var fade = 1
    @State private var stability = "Stable"
    
    let stabilityOptions = ["Very Understable", "Understable", "Stable", "Overstable", "Very Overstable"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Disc Info")) {
                    TextField("Disc Name", text: $name)
                    TextField("Brand", text: $brand)
                    
                    Picker("Stability", selection: $stability) {
                        ForEach(stabilityOptions, id: \.self) { stability in
                            Text(stability)
                        }
                    }
                }
                
                Section(header: Text("Flight Numbers")) {
                    VStack(spacing: 16) {
                        FlightNumberSlider(label: "Speed", value: $speed, range: 1...14)
                        FlightNumberSlider(label: "Glide", value: $glide, range: 1...7)
                        FlightNumberSlider(label: "Turn", value: $turn, range: -5...1)
                        FlightNumberSlider(label: "Fade", value: $fade, range: 0...5)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Add to Bag") {
                        addDisc()
                    }
                    .disabled(name.isEmpty || brand.isEmpty)
                }
            }
            .navigationTitle("Add New Disc")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
    
    private func addDisc() {
        let newDisc = Disc(
            name: name,
            brand: brand,
            speed: speed,
            glide: glide,
            turn: turn,
            fade: fade,
            stability: stability
        )
        appData.myDiscs.append(newDisc)
        dismiss()
    }
}

struct FlightNumberSlider: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
        }
    }
}