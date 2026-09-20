import Foundation
import CoreLocation
import Observation

private struct PlaceStoreKey: Hashable {
    let lat: Double;    // rounded to 3 dp (~110 m bucket)
    let lng: Double;
    let typeId: Int;    // 0 = all types
    let locale: String;

    init(location: CLLocationCoordinate2D, type: KGDataTourInfo.ContentType?) {
        self.lat    = (location.latitude  * 1000).rounded() / 1000;
        self.lng    = (location.longitude * 1000).rounded() / 1000;
        self.typeId = type?.rawValue ?? 0;
        self.locale = Locale.current.identifier;
    }
}

private struct PlaceStore {
    var places: [String: KGDataTourInfo] = [:];   // contentid → info
    var maxFetchedRadius: Int = 0;
    var date: Date = Date();

    var isStale: Bool { Date().timeIntervalSince(date) > 600; }  // 10-min TTL

    mutating func merge(_ items: [KGDataTourInfo]) {
        for item in items {
            guard let id = item.fields[KGDataTourInfo.fieldNames.id] as? String else { continue; }
            places[id] = item;
        }
        date = Date();
    }

    func filtered(within radius: Int, from center: CLLocationCoordinate2D) -> [KGDataTourInfo] {
        let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude);
        return places.values
            .filter { info in
                guard let coord = info.location else { return false; }
                let dist = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                    .distance(from: centerLoc);
                return dist <= Double(radius);
            }
            .sorted { a, b in
                let distA = CLLocation(latitude: a.location!.latitude, longitude: a.location!.longitude).distance(from: centerLoc);
                let distB = CLLocation(latitude: b.location!.latitude, longitude: b.location!.longitude).distance(from: centerLoc);
                return distA < distB;
            };
    }
}

@Observable
class TourListViewModel {
    var infos: [KGDataTourInfo] = [];
    var isLoading: Bool = false;
    var selectedType: KGDataTourInfo.ContentType? = nil;
    var radius: Int = 3000;
    var location: CLLocationCoordinate2D? = nil;
    var totalCount: Int = 0;

    var hasMorePages: Bool { totalCount > 0 && infos.count < totalCount; }

    private var lastRequest: KGDataTourListRequest? = nil;
    private var isFetchingNext: Bool = false;
    private var placeStores: [PlaceStoreKey: PlaceStore] = [:];

    func fetchList() {
        guard let loc = location else { return };

        let storeKey = PlaceStoreKey(location: loc, type: selectedType);

        if let store = placeStores[storeKey], !store.isStale, store.maxFetchedRadius >= radius {
            let filtered = store.filtered(within: radius, from: loc);
            infos          = filtered;
            totalCount     = filtered.count;   // hasMorePages = false → load-more disabled
            lastRequest    = nil;
            isFetchingNext = false;
            print("[TourListVM] store hit — \(filtered.count) items (store has \(store.places.count), maxR: \(store.maxFetchedRadius))");
            return;
        }

        isLoading      = true;
        // NOTE: infos NOT cleared — old results stay visible during network load
        totalCount     = 0;
        lastRequest    = nil;
        isFetchingNext = false;

        print("[TourListVM] fetchList() network call — radius: \(radius)");
        lastRequest = KGDataTourManager.shared.requestList(
            type: selectedType,
            location: loc,
            radius: UInt(radius)
        ) { [weak self] (page, items, total, error) in
            guard let self = self else { return };
            DispatchQueue.main.async {
                self.totalCount = total;
                self.infos      = items;
                self.isLoading  = false;
                var store = self.placeStores[storeKey] ?? PlaceStore();
                store.merge(items);
                store.maxFetchedRadius = max(store.maxFetchedRadius, self.radius);
                self.placeStores[storeKey] = store;
                print("[TourListVM] page \(page) loaded — items: \(items.count), total: \(total), hasMorePages: \(self.hasMorePages)");
            }
        };
    }

    func fetchNextPage() {
        guard !isFetchingNext, let next = lastRequest?.next else { return };
        isFetchingNext = true;
        lastRequest = next;

        KGDataTourManager.shared.requestList(request: next) { [weak self] (page, items, total, error) in
            guard let self = self else { return };
            DispatchQueue.main.async {
                self.infos.append(contentsOf: items);
                self.isFetchingNext = false;
            }
        };
    }

    func fetchAllPages() {
        print("[TourListVM] fetchAllPages() called — isFetchingNext: \(isFetchingNext), hasMorePages: \(hasMorePages), lastRequest.page: \(lastRequest?.page ?? -1)");
        guard !isFetchingNext, hasMorePages, let next = lastRequest?.next else {
            print("[TourListVM] fetchAllPages() guard failed — isFetchingNext: \(isFetchingNext), hasMorePages: \(hasMorePages), lastRequest: \(lastRequest == nil ? "nil" : "page \(lastRequest!.page)")");
            return;
        };
        isFetchingNext = true;
        lastRequest = next;
        print("[TourListVM] fetching page \(next.page)...");

        KGDataTourManager.shared.requestList(request: next) { [weak self] (page, items, total, error) in
            guard let self = self else { return };
            DispatchQueue.main.async {
                self.infos.append(contentsOf: items);
                self.isFetchingNext = false;
                print("[TourListVM] fetchAllPages page \(page) loaded — items: \(items.count), infos: \(self.infos.count)/\(self.totalCount), hasMorePages: \(self.hasMorePages)");
                if let loc = self.location {
                    let storeKey = PlaceStoreKey(location: loc, type: self.selectedType);
                    var store = self.placeStores[storeKey] ?? PlaceStore();
                    store.merge(items);
                    store.maxFetchedRadius = max(store.maxFetchedRadius, self.radius);
                    self.placeStores[storeKey] = store;
                }
                if self.hasMorePages {
                    self.fetchAllPages();
                }
            }
        };
    }

    func refresh() async {
        guard let loc = location else { return };
        let storeKey = PlaceStoreKey(location: loc, type: selectedType);
        placeStores.removeValue(forKey: storeKey);
        fetchList();
    }
}
