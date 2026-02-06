import SwiftUI

struct MainScreen: View {
    @EnvironmentObject var adManager: SwiftUIAdManager

    var body: some View {
        TourMapScreen()
            .environmentObject(adManager)
    }
}
