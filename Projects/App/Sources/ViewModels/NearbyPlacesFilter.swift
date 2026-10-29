import Foundation
import CoreLocation
import MapKit

/// One row of the nearby-places panel. The distance is resolved once here
/// (`KGDataTourInfo.distance(from:)` re-parses the field dictionary on every
/// call), so rows and the sort never recompute it.
struct NearbyPlace: Identifiable {
    let id: Int;
    let info: KGDataTourInfo;
    let distance: Int?;
}

struct NearbyPlacesResult {
    /// The selected place first (when there is one), then the rest by distance.
    var places: [NearbyPlace] = [];
    /// Places inside the region plus the selected place when it is outside —
    /// before the row cap is applied.
    var totalCount: Int = 0;
    var isTruncated: Bool = false;
}

/// Pure list building for the nearby-places panel: region filter, selected
/// place injection, distance sort and row cap. Kept free of SwiftUI state so
/// it can run once per input change (never inside `body`) and be unit tested.
enum NearbyPlacesFilter {
    static let maxRows = 300;

    /// `region` nil means no region filter (nothing has settled yet).
    /// `origin` is the point distances are measured from — GPS when
    /// available, otherwise whatever the caller chooses (e.g. the map center).
    static func make(
        infos: [KGDataTourInfo],
        region: MKCoordinateRegion?,
        selected: KGDataTourInfo?,
        origin: CLLocationCoordinate2D?,
        limit: Int = maxRows
    ) -> NearbyPlacesResult {
        let selectedId = selected?.id;

        var candidates: [NearbyPlace] = [];
        var seen = Set<Int>();
        for info in infos {
            guard let id = info.id, id != selectedId, !seen.contains(id) else { continue; }
            guard let coord = info.location else { continue; }
            if let region = region, !contains(region, coord) { continue; }
            seen.insert(id);
            candidates.append(NearbyPlace(id: id, info: info, distance: info.distance(from: origin)));
        }

        candidates.sort { a, b in
            switch (a.distance, b.distance) {
            case let (x?, y?): return x != y ? x < y : a.id < b.id;
            case (_?, nil):    return true;
            case (nil, _?):    return false;
            case (nil, nil):   return a.id < b.id;
            }
        };

        var result = NearbyPlacesResult();
        let truncated = candidates.count > limit;
        if truncated { candidates.removeSubrange(limit...); }

        var rows: [NearbyPlace] = [];
        var total = seen.count;
        if let selected = selected, let id = selectedId {
            rows.append(NearbyPlace(id: id, info: selected, distance: selected.distance(from: origin)));
            total += 1;
        }
        rows.append(contentsOf: candidates);

        result.places = rows;
        result.totalCount = total;
        result.isTruncated = truncated;
        return result;
    }

    /// Plain lat/lon box test — the visible map area is far smaller than any
    /// span where the antimeridian or poles matter for Korea.
    static func contains(_ region: MKCoordinateRegion, _ coord: CLLocationCoordinate2D) -> Bool {
        abs(coord.latitude - region.center.latitude) <= region.span.latitudeDelta / 2
            && abs(coord.longitude - region.center.longitude) <= region.span.longitudeDelta / 2;
    }
}
