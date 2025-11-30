import SwiftUI
struct DiscSelectionView: View {
    @ObservedObject var appData: AppData
    let onManageDiscs: () -> Void
    
    var body: some View {
        NavigationView {
            List(appData.myDiscs, id: \.name) { disc in
                VStack(alignment: .leading) {
                    Text(disc.name)
                        .font(.headline)
                    Text("\(disc.brand) • Speed: \(disc.speed) • Glide: \(disc.glide)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("My Discs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage") {
                        onManageDiscs()
                    }
                }
            }
        }
    }
}
