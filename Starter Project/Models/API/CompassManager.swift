//
//  CompassManager.swift
//  Starter Project
//
//  Created by Matt Wilderson on 11/29/25.
//


import Foundation
import CoreLocation
import Combine

class CompassManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var heading: Double = 0
    @Published var throwDirection: String = "North"
    @Published var isAvailable = false
    
    private var throwDirectionCallback: ((String) -> Void)?
    
    override init() {
        super.init()
        setupCompass()
    }
    
    private func setupCompass() {
        guard CLLocationManager.headingAvailable() else {
            isAvailable = false
            return
        }
        
        locationManager.delegate = self
        locationManager.headingFilter = 5.0 // 5 degree changes
        isAvailable = true
    }
    
    func startUpdatingHeading(callback: @escaping (String) -> Void) {
        guard isAvailable else { return }
        self.throwDirectionCallback = callback
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }
    
    private func degreesToCardinal(_ degrees: Double) -> String {
        let cardinals = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
        let index = Int((degrees + 22.5) / 45.0) % 8
        return cardinals[index]
    }
}

extension CompassManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let trueHeading = newHeading.trueHeading
        heading = trueHeading
        let direction = degreesToCardinal(trueHeading)
        throwDirection = direction
        throwDirectionCallback?(direction)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Compass error: \(error.localizedDescription)")
    }
}