import Foundation
import CoreLocation
import Observation

@Observable
class DeepLinkManager {
    static let shared = DeepLinkManager();

    var contentId: Int? = nil;
    var srcLocation: CLLocationCoordinate2D? = nil;

    func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return };

        let contentIdStr = queryItems.first(where: { $0.name == "destContentId" })?.value ?? "";
        let srcLat = queryItems.first(where: { $0.name == "srcLatitude" })?.value ?? "";
        let srcLong = queryItems.first(where: { $0.name == "srcLongitude" })?.value ?? "";

        guard let id = Int(contentIdStr) else { return };

        if !srcLat.isEmpty, !srcLong.isEmpty,
           let lat = CLLocationDegrees(srcLat),
           let lng = CLLocationDegrees(srcLong) {
            srcLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng);
        }

        contentId = id;
    }

    func consume() {
        contentId = nil;
        srcLocation = nil;
    }
}
