import SwiftUI
import CoreLocation

// MARK: - Detents & layout

enum NearbyPanelDetent {
    case collapsed, half, large

    /// Header tap / VoiceOver action order.
    var next: NearbyPanelDetent {
        switch self {
        case .collapsed: return .half;
        case .half:      return .large;
        case .large:     return .collapsed;
        }
    }
}

/// Pure panel sizing, shared by the panel itself and the screen (which needs
/// the height to place the map controls and offset the camera).
enum NearbyPanelLayout {
    static let bannerHeight: CGFloat = 50;
    static let headerHeight: CGFloat = 56;
    static let compactRowHeight: CGFloat = 76;
    static let collapsedHeight: CGFloat = 76;
    static let collapsedSelectedHeight: CGFloat = headerHeight + compactRowHeight;
    static let navBarGap: CGFloat = 8;

    /// `available` is the container height minus the banner ad.
    static func height(for detent: NearbyPanelDetent, available: CGFloat, hasSelection: Bool) -> CGFloat {
        let collapsed = hasSelection ? collapsedSelectedHeight : collapsedHeight;
        let large = max(collapsed, min(available * 0.85, available - navBarGap));
        let half = min(max(available * 0.4, 280), 380);
        switch detent {
        case .collapsed: return collapsed;
        case .half:      return min(half, large);
        case .large:     return large;
        }
    }

    static func animation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.85);
    }
}

// MARK: - Content state

enum NearbyPanelContent {
    case loading, zoomIn, empty, list
}

// MARK: - Panel

struct NearbyPlacesPanel: View {
    let places: [NearbyPlace]
    let totalCount: Int
    let isTruncated: Bool
    let content: NearbyPanelContent
    let selectedId: Int?
    let favoriteIds: Set<Int>
    let showsDistance: Bool
    // Paging progress ("n / total" + spinner in the header) while the
    // viewport's remaining pages are still loading.
    let loadedCount: Int
    let pagingTotal: Int
    let isPaging: Bool
    let availableHeight: CGFloat
    @Binding var detent: NearbyPanelDetent
    let onSelect: (KGDataTourInfo) -> Void
    let onOpenDetails: (KGDataTourInfo) -> Void
    let onToggleFavorite: (KGDataTourInfo) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var dragTranslation: CGFloat = 0

    private var hasSelection: Bool { selectedId != nil; }

    private func height(for detent: NearbyPanelDetent) -> CGFloat {
        NearbyPanelLayout.height(for: detent, available: availableHeight, hasSelection: hasSelection);
    }

    private var currentHeight: CGFloat {
        let low = height(for: .collapsed);
        let high = height(for: .large);
        return min(max(height(for: detent) - dragTranslation, low), high);
    }

    private var showsList: Bool {
        currentHeight > height(for: .collapsed) + 1;
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if showsList {
                Divider()
                listContent
            } else if let selected = places.first(where: { $0.id == selectedId }) {
                compactSelectedRow(selected)
            }
        }
        .frame(height: currentHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        .shadow(color: .black.opacity(0.16), radius: 10, y: -4)
    }

    // MARK: Header

    private var header: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(Color(.systemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            HStack {
                Text("Nearby places".localized())
                    .font(.subheadline.weight(.semibold))
                Spacer()
                headerTrailing
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
        }
        .frame(height: NearbyPanelLayout.headerHeight)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { setDetent(detent.next); }
        .gesture(dragGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(headerAccessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("Expand".localized())) { setDetent(detent == .collapsed ? .half : .large); }
        .accessibilityAction(named: Text("Collapse".localized())) { setDetent(detent == .large ? .half : .collapsed); }
        .accessibilityAction { setDetent(detent.next); }
    }

    @ViewBuilder
    private var headerTrailing: some View {
        if isPaging {
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("\(loadedCount) / \(pagingTotal)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        } else if content == .list {
            Text("\(totalCount)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var headerAccessibilityLabel: String {
        let state: String;
        switch detent {
        case .collapsed: state = "Collapsed".localized();
        case .half:      state = "Half".localized();
        case .large:     state = "Expanded".localized();
        }
        return "\("Nearby places".localized()), \(totalCount), \(state)";
    }

    private func setDetent(_ new: NearbyPanelDetent) {
        withAnimation(NearbyPanelLayout.animation(reduceMotion: reduceMotion)) { detent = new; }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.height;
            }
            .onEnded { value in
                // Snap to the detent nearest to where the flick would land.
                let projected = height(for: detent) - value.predictedEndTranslation.height;
                let target = NearbyPanelDetentSnapper.nearest(
                    to: projected,
                    heights: [
                        (.collapsed, height(for: .collapsed)),
                        (.half, height(for: .half)),
                        (.large, height(for: .large)),
                    ]
                );
                setDetent(target);
            }
    }

    // MARK: Content

    @ViewBuilder
    private var listContent: some View {
        switch content {
        case .loading:
            skeleton
        case .zoomIn:
            message(icon: "arrow.up.left.and.arrow.down.right", text: "Zoom in to see places".localized())
        case .empty:
            message(icon: "mappin.slash", text: "No places here...".localized())
        case .list:
            placeList
        }
    }

    private var placeList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(places) { place in
                        NearbyPlaceRow(
                            place: place,
                            isSelected: place.id == selectedId,
                            isFavorite: favoriteIds.contains(place.id),
                            showsDistance: showsDistance,
                            onTap: {
                                if place.id == selectedId { onOpenDetails(place.info); }
                                else { onSelect(place.info); }
                            },
                            onOpenDetails: { onOpenDetails(place.info); },
                            onToggleFavorite: { onToggleFavorite(place.info); }
                        )
                        .id(place.id)
                    }
                    if isTruncated {
                        Text("Zoom in to see more".localized())
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
            }
            // The list keeps its order, so just bring the selection into view
            // (nil anchor = minimal scroll; a visible row doesn't move).
            .onChange(of: selectedId) { _, _ in scrollToSelected(proxy, animated: true); }
            .onAppear { scrollToSelected(proxy, animated: false); }
        }
    }

    private func scrollToSelected(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let id = selectedId, places.contains(where: { $0.id == id }) else { return };
        if animated {
            withAnimation(NearbyPanelLayout.animation(reduceMotion: reduceMotion)) { proxy.scrollTo(id); }
        } else {
            proxy.scrollTo(id);
        }
    }

    private var skeleton: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Placeholder place name")
                            .font(.subheadline.weight(.semibold))
                        Text("Placeholder address line")
                            .font(.caption)
                        Text("0.0 km")
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(minHeight: 72)
            }
            Spacer(minLength: 0)
        }
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }

    private func message(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(text)
                .font(.subheadline)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }

    // Collapsed with a selection: just the place, tappable to open details.
    private func compactSelectedRow(_ place: NearbyPlace) -> some View {
        HStack(spacing: 12) {
            NearbyPlaceThumbnail(info: place.info, size: 48, showsBadge: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.info.title ?? "")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                NearbyPlaceMetaLine(place: place, showsDistance: showsDistance)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 19)
        .padding(.trailing, 12)
        .frame(height: NearbyPanelLayout.compactRowHeight)
        .background(Color.blue.opacity(0.12))
        .overlay(alignment: .leading) { Color.blue.frame(width: 3); }
        .overlay(alignment: .top) { Divider(); }
        .contentShape(Rectangle())
        .onTapGesture { onOpenDetails(place.info); }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens details".localized())
    }
}

/// Picks the detent whose height is nearest to `projected`.
enum NearbyPanelDetentSnapper {
    static func nearest(to projected: CGFloat, heights: [(NearbyPanelDetent, CGFloat)]) -> NearbyPanelDetent {
        heights.min { abs($0.1 - projected) < abs($1.1 - projected) }?.0 ?? .half;
    }
}

// MARK: - Row pieces

private struct NearbyPlaceThumbnail: View {
    let info: KGDataTourInfo
    let size: CGFloat
    var showsBadge: Bool = true

    var body: some View {
        let type = info.type;
        AsyncImage(url: info.thumbnail) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            CategoryPlaceholderView(type: type, showIcon: true, iconSize: size * 0.45)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .bottomTrailing) {
            if showsBadge {
                Image(systemName: type.markerIconName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(type.markerColor, in: Circle())
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
                    .offset(x: 4, y: 4)
            }
        }
    }
}

private struct NearbyPlaceMetaLine: View {
    let place: NearbyPlace
    let showsDistance: Bool

    var body: some View {
        let typeName = place.info.type.stringValue.localized();
        if showsDistance, let distance = place.distance {
            (Text(distance.stringForDistance())
                .font(.caption.weight(.medium))
                .foregroundColor(.blue)
             + Text(" · \(typeName)")
                .font(.caption)
                .foregroundColor(.secondary))
                .lineLimit(1)
        } else {
            Text(typeName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

private struct NearbyPlaceRow: View {
    let place: NearbyPlace
    let isSelected: Bool
    let isFavorite: Bool
    let showsDistance: Bool
    let onTap: () -> Void
    let onOpenDetails: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                info
                    .contentShape(Rectangle())
                    .onTapGesture { onTap(); }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                heartButton
            }
            if isSelected {
                HStack {
                    Spacer()
                    Button(action: onOpenDetails) {
                        HStack(spacing: 4) {
                            Text("Open details".localized())
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 40)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.trailing, 8)
                    .padding(.bottom, 12)
                }
            }
        }
        .padding(.leading, isSelected ? 19 : 16)
        .padding(.top, isSelected ? 10 : 0)
        .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
        .overlay(alignment: .leading) {
            if isSelected { Color.blue.frame(width: 3); }
        }
        .overlay(alignment: .bottom) { Divider(); }
    }

    private var info: some View {
        HStack(spacing: 12) {
            NearbyPlaceThumbnail(info: place.info, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.info.title ?? "")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let addr = place.info.primaryAddr, !addr.isEmpty {
                    Text(addr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if isSelected, let tel = place.info.tel, !tel.isEmpty {
                    Text(tel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                NearbyPlaceMetaLine(place: place, showsDistance: showsDistance)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 72)
    }

    private var heartButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundStyle(isFavorite ? Color.red : Color.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites".localized() : "Add to favorites".localized())
    }
}
