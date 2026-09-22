import SwiftUI
import CoreLocation

struct TourCellView: View {
    let info: KGDataTourInfo
    // GPS location for client-side distance. Defaults to nil so existing call
    // sites (TourListScreen) keep compiling unchanged and fall back to the
    // API's `dist` field.
    var currentLocation: CLLocationCoordinate2D? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image via SDWebImage for caching
            SDWebImageSwiftUIView(url: info.thumbnail, placeholder: WWGImages.noImage)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()
                .overlay(Color.black.opacity(0.3))

            VStack(alignment: .leading, spacing: 4) {
                Text(info.title ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let dist = info.distance(from: currentLocation) {
                    Text(dist.stringForDistance())
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
}
