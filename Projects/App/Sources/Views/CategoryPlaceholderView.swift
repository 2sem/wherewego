import SwiftUI

/// Category-colored gradient (+ optional icon) shown wherever a tour's photo is
/// unavailable — no thumbnail URL, or the image failed/hasn't loaded yet. Shared by
/// TourInfoScreen (hero image placeholder) and TourCellView (list/favorites thumbnail)
/// so both screens agree on one placeholder look instead of `WWGImages.noImage`.
struct CategoryPlaceholderView: View {
    let type: KGDataTourInfo.ContentType?
    var showIcon: Bool = false;
    var iconSize: CGFloat = 100;
    var iconOffsetY: CGFloat = 0;

    var body: some View {
        ZStack(alignment: .center) {
            LinearGradient(
                colors: Self.gradientColors(for: type),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if showIcon {
                Image(systemName: Self.icon(for: type))
                    .font(.system(size: iconSize, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.15))
                    .offset(y: iconOffsetY)
            }
        }
    }

    static func gradientColors(for type: KGDataTourInfo.ContentType?) -> [Color] {
        guard let type = type else {
            return [Color(red: 0.0, green: 0.66, blue: 0.59), Color(red: 0.0, green: 0.48, blue: 1.0)]  // Default teal to blue
        }

        switch type {
        case .Tour, .Tour_Foreign:
            return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.4, blue: 0.0)]  // Orange
        case .Culture, .Culture_Foreign:
            return [Color(red: 0.6, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.2, blue: 0.6)]  // Purple
        case .Event, .Event_Foreign:
            return [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 0.9, green: 0.1, blue: 0.3)]  // Pink
        case .Course:
            return [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.7)]  // Blue
        case .Leports, .Leports_Foreign:
            return [Color(red: 0.3, green: 0.8, blue: 0.3), Color(red: 0.2, green: 0.6, blue: 0.2)]  // Green
        case .Hotel, .Hotel_Foreign:
            return [Color(red: 0.4, green: 0.5, blue: 0.7), Color(red: 0.2, green: 0.3, blue: 0.5)]  // Navy
        case .Shopping, .Shopping_Foreign:
            return [Color(red: 0.9, green: 0.5, blue: 0.8), Color(red: 0.7, green: 0.3, blue: 0.6)]  // Magenta
        case .Food, .Food_Foreign:
            return [Color(red: 0.0, green: 0.66, blue: 0.59), Color(red: 0.0, green: 0.48, blue: 1.0)]  // Teal to blue
        case .Travel, .Travel_Foreign:
            return [Color(red: 0.5, green: 0.7, blue: 0.9), Color(red: 0.3, green: 0.5, blue: 0.7)]  // Sky blue
        }
    }

    static func icon(for type: KGDataTourInfo.ContentType?) -> String {
        guard let type = type else { return "mappin.circle.fill" }

        switch type {
        case .Tour, .Tour_Foreign:           return "camera.fill"
        case .Culture, .Culture_Foreign:     return "building.columns.fill"
        case .Event, .Event_Foreign:         return "party.popper.fill"
        case .Course:                        return "map.fill"
        case .Leports, .Leports_Foreign:     return "figure.run"
        case .Hotel, .Hotel_Foreign:         return "bed.double.fill"
        case .Shopping, .Shopping_Foreign:   return "cart.fill"
        case .Food, .Food_Foreign:           return "fork.knife"
        case .Travel, .Travel_Foreign:       return "airplane"
        }
    }
}
