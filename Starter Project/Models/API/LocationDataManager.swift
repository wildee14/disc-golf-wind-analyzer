import CoreLocation

class LocationDataManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var currentLocation: CLLocation?
    @Published var isUsingManualLocation = false
    @Published var manualLocationName = "Current Location"
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Better for weather data
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            authorizationStatus = .authorizedWhenInUse
            locationManager.requestLocation()
            isUsingManualLocation = false
        case .restricted, .denied:
            authorizationStatus = .restricted
            isUsingManualLocation = true
            manualLocationName = "Location Disabled"
        case .notDetermined:
            authorizationStatus = .notDetermined
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            isUsingManualLocation = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        isUsingManualLocation = true
        manualLocationName = "Location Error"
    }
    
    func setManualLocation(name: String) {
        isUsingManualLocation = true
        manualLocationName = name
    }
    
    var latitude: Double {
        currentLocation?.coordinate.latitude ?? 0.0
    }
    
    var longitude: Double {
        currentLocation?.coordinate.longitude ?? 0.0
    }
}
