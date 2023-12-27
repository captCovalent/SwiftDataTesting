/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 The app's top level navigation split view.
 */

import SwiftUI
import SwiftData

/// The app's top level navigation split view.
struct ContentView: View {
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @Query private var quakes: [Quake]
    
    /// The identifier of the selected earthquake.
    ///
    /// The list controls this value through a binding, and most of the app's
    /// interface relies on this value, with one exception: the map view binds
    /// to a separate selection value. The app synchronizes these selections,
    /// but using separate values enables the app to detect when someone taps
    /// on the map so that it can scroll the list to match.
    @State private var selectedId: Quake.ID? = nil
    
    /// The identifier of the earthquake that the map highlights.
    ///
    /// This distinct map selection state enables the app to use
    /// changes in map selection to drive scroll changes in the list.
    @State private var selectedIdMap: Quake.ID? = nil
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationSplitView {
            QuakeList(
                selectedId: $selectedId,
                selectedIdMap: $selectedIdMap,
                searchText: viewModel.searchText,
                searchDate: viewModel.searchDate,
                sortParameter: viewModel.sortParameter,
                sortOrder: viewModel.sortOrder
            )
            .searchable(text: $viewModel.searchText)
            .toolbar {
                // In iOS, the refreshable modifier provides pull-to-refresh.
                // In macOS, add a refresh button to the toolbar instead.
#if os(macOS)
                RefreshButton()
#endif
                
                DeleteButton(selectedId: $selectedId)
                SortButton()
                Button {
                    addQuakes(count: 10000, to: modelContext)
                } label: {
                    Label("Add", systemImage: "plus").labelStyle(.iconOnly)
                }
                
            }
            
            // This modifier creates a pull-to-refresh in iOS, but also sets
            // the refresh action in the environment, which the custom macOS
            // RefreshButton uses.
            .refreshable {
                await GeoFeatureCollection.refresh(modelContext: modelContext)
                viewModel.update(modelContext: modelContext)
            }
            .navigationTitle("Earthquakes")
        } detail: {
            //            MapView(
            //                selectedId: $selectedId,
            //                selectedIdMap: $selectedIdMap,
            //                searchDate: viewModel.searchDate,
            //                searchText: viewModel.searchText
            //            )
            Group {
                if let selectedQuake = quakes.first(where: { $0.id == selectedId }) {
                    Text("Magnitude: \(selectedQuake.magnitudeString)")
                        .font(.title)
                } else {
                    Text("Select an Earthquake")
                }
            }
#if os(macOS)
            .navigationTitle(quakes[selectedId]?.location.name ?? "Earthquakes")
            .navigationSubtitle(quakes[selectedId]?.fullDate ?? "")
#else
            .navigationTitle(quakes[selectedId]?.location.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
        .onChange(of: scenePhase) { _, scenePhase in
            if scenePhase == .active {
                viewModel.update(modelContext: modelContext)
            }
        }
    }
}

extension ContentView {
    func addQuakes(count: Int, to modelContext: ModelContext) {
        for _ in 0..<count {
            let quake = generateRandomQuake()
            try? modelContext.insert(quake)
        }
        viewModel.update(modelContext: modelContext)
    }
    
    /// Generates a random earthquake.
    /// - Returns: A `Quake` object with random properties.
    private func generateRandomQuake() -> Quake {
        // Generate random data for the quake
        let code = UUID().uuidString
        let magnitude = Double.random(in: 0...10)
        let time = Date()// Random date within the past year
        let name = "Random Location"
        let longitude = Double.random(in: -180...180)
        let latitude = Double.random(in: -90...90)
        
        return Quake(code: code, magnitude: magnitude, time: time, name: name, longitude: longitude, latitude: latitude)
    }
}

#Preview {
    ContentView()
        .environment(ViewModel())
        .modelContainer(for: Quake.self, inMemory: true)
}
