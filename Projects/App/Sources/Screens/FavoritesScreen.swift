import SwiftUI
import CoreLocation

struct FavoritesScreen: View {
    let currentLocation: CLLocationCoordinate2D?
    @Binding var navPath: [TourNavDestination]

    @EnvironmentObject var adManager: SwiftUIAdManager
    @Environment(\.dismiss) private var dismiss;

    @State private var favorites: [KGDataTourInfo] = [];

    var body: some View {
        contentBody
            .navigationTitle("Favorite".localized())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { reloadFavorites(); }
    }

    // MARK: - Sub-views (broken out to help the type-checker)

    private var contentBody: some View {
        VStack(spacing: 0) {
            favoritesList

            // Banner ad
            bannerAdView
        }
    }

    private var favoritesList: some View {
        List {
            ForEach(favorites, id: \.id) { info in
                TourCellView(info: info)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigateToDetail(info: info);
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Double tap to view details.".localized())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            removeFavorite(info);
                        } label: {
                            Label("Remove".localized(), systemImage: "heart.slash")
                        }
                        .accessibilityLabel("Remove from Favorites".localized())
                    }
            }
        }
        .listStyle(.plain)
        .overlay {
            if favorites.isEmpty {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No Favorites Yet".localized())
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Tap the heart icon on any place to save it here.".localized())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss();
            } label: {
                Text("Explore Nearby Places".localized())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(.horizontal, 32)
    }

    private var bannerAdView: some View {
        BannerAdView(unitName: .homeBanner)
            .frame(height: 50)
            .frame(maxWidth: .infinity);
    }

    // MARK: - Helpers

    private func reloadFavorites() {
        withAnimation {
            favorites = Array(WWGDefaults.FavoritePlaces.reversed());
        }
    }

    private func removeFavorite(_ info: KGDataTourInfo) {
        guard let id = info.id else { return };
        WWGDefaults.removeFavorite(id: id);
        withAnimation {
            favorites.removeAll { $0.id == id };
        }
    }

    private func navigateToDetail(info: KGDataTourInfo) {
        Task {
            await adManager.show(unit: .full);
            navPath.append(.tourInfo(info, currentLocation));
        }
    }
}
