import Foundation
class AppData: ObservableObject {
    @Published var currentConditions = FlightCondition(
        windSpeed: 5,
        windDirection: "Headwind",
        temperature: 70,
        elevation: 500,
        humidity: 60
    )
    
    @Published var myDiscs = [
        Disc(name: "Destroyer", brand: "Innova", speed: 12, glide: 5, turn: -1, fade: 3, stability: "Overstable"),
        Disc(name: "Buzzz", brand: "Discraft", speed: 5, glide: 4, turn: -1, fade: 1, stability: "Stable"),
        Disc(name: "Leopard3", brand: "Innova", speed: 7, glide: 5, turn: -2, fade: 1, stability: "Understable"),
        Disc(name: "Firebird", brand: "Innova", speed: 9, glide: 3, turn: 0, fade: 4, stability: "Very Overstable"),
        Disc(name: "Tern", brand: "Innova", speed: 12, glide: 6, turn: -3, fade: 2, stability: "Understable"),
        Disc(name: "Roc3", brand: "Innova", speed: 5, glide: 4, turn: 0, fade: 3, stability: "Overstable")
    ]
}
