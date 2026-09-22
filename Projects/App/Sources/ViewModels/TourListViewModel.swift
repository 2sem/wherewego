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
    // Farthest item distance (API `dist`, meters from this store's center)
    // merged so far. Drives recordCoverage(radius:complete:) below so
    // maxFetchedRadius can never claim more than what's actually been loaded.
    var farthestLoadedDistance: Int = 0;
    var date: Date = Date();

    var isStale: Bool { Date().timeIntervalSince(date) > 600; }  // 10-min TTL

    mutating func merge(_ items: [KGDataTourInfo]) {
        for item in items {
            guard let id = item.fields[KGDataTourInfo.fieldNames.id] as? String else { continue; }
            places[id] = item;
            if let d = item.distance { farthestLoadedDistance = max(farthestLoadedDistance, d); }
        }
        date = Date();
    }

    /// Updates the store's coverage claim for `radius`. `complete` must only
    /// be true once every page for that radius has actually been merged
    /// (all pages loaded, or a superseded chain that legitimately finished);
    /// otherwise this only claims out to the farthest item actually loaded
    /// so far, capped at `radius` — it never over-claims while pages are
    /// still in flight or a fetch was superseded mid-chain.
    mutating func recordCoverage(radius: Int, complete: Bool) {
        let claim = complete ? radius : min(radius, farthestLoadedDistance);
        maxFetchedRadius = max(maxFetchedRadius, claim);
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

    // Bumped on every fetchList() call, network or cache-hit path alike.
    // Every in-flight callback captures the generation it was issued under
    // (plus its own location/radius/store key) at request time and never
    // reads `self.location`/`self.radius` later — only a callback whose
    // captured generation still matches `self.generation` when it returns is
    // allowed to touch infos/totalCount/isLoading/isFetchingNext or continue
    // the pages chain. A superseded response still merges into the store for
    // its own key/radius (so that work isn't wasted), but nothing else.
    private var generation: Int = 0;
    // The generation the currently in-flight `lastRequest` chain belongs to.
    private var lastRequestGeneration: Int = 0;

    func fetchList() {
        guard let loc = location else { return };

        generation += 1;
        let gen = generation;
        let requestType = selectedType;
        let requestRadius = radius;
        let storeKey = PlaceStoreKey(location: loc, type: requestType);

        if let store = placeStores[storeKey], !store.isStale, store.maxFetchedRadius >= requestRadius {
            let filtered = store.filtered(within: requestRadius, from: loc);
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

        print("[TourListVM] fetchList() network call — radius: \(requestRadius), gen: \(gen)");
        lastRequestGeneration = gen;
        lastRequest = KGDataTourManager.shared.requestList(
            type: requestType,
            location: loc,
            radius: UInt(requestRadius)
        ) { [weak self] (page, items, total, error) in
            DispatchQueue.main.async {
                self?.handleFirstPage(items: items, total: total, generation: gen, storeKey: storeKey, requestRadius: requestRadius);
            }
        };
    }

    private func handleFirstPage(items: [KGDataTourInfo], total: Int, generation gen: Int, storeKey: PlaceStoreKey, requestRadius: Int) {
        var store = placeStores[storeKey] ?? PlaceStore();
        store.merge(items);
        let complete = items.count >= total;
        store.recordCoverage(radius: requestRadius, complete: complete);
        placeStores[storeKey] = store;

        guard gen == generation else {
            print("[TourListVM] page 1 (gen \(gen)) superseded by gen \(generation) — merged into store only");
            return;
        };

        totalCount = total;
        infos      = items;
        isLoading  = false;
        if complete { lastRequest = nil; }
        print("[TourListVM] page 1 loaded — items: \(items.count), total: \(total), hasMorePages: \(hasMorePages)");
    }

    func fetchNextPage() {
        guard !isFetchingNext, let next = lastRequest?.next else { return };
        isFetchingNext = true;
        lastRequest = next;
        let gen = lastRequestGeneration;
        let storeKey = PlaceStoreKey(location: next.location, type: next.type);
        let requestRadius = Int(next.radius);

        KGDataTourManager.shared.requestList(request: next) { [weak self] (page, items, total, error) in
            DispatchQueue.main.async {
                self?.handleSubsequentPage(items: items, total: total, generation: gen, storeKey: storeKey, requestRadius: requestRadius, continueChain: false);
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
        let gen = lastRequestGeneration;
        let storeKey = PlaceStoreKey(location: next.location, type: next.type);
        let requestRadius = Int(next.radius);
        print("[TourListVM] fetching page \(next.page)... (gen \(gen))");

        KGDataTourManager.shared.requestList(request: next) { [weak self] (page, items, total, error) in
            DispatchQueue.main.async {
                self?.handleSubsequentPage(items: items, total: total, generation: gen, storeKey: storeKey, requestRadius: requestRadius, continueChain: true);
            }
        };
    }

    private func handleSubsequentPage(items: [KGDataTourInfo], total: Int, generation gen: Int, storeKey: PlaceStoreKey, requestRadius: Int, continueChain: Bool) {
        // Conservative default: only claim what's verifiably been loaded so
        // far. If this response turns out to complete the chain (checked
        // below, gated on generation so we're reading this exact chain's own
        // accumulated state), the claim is upgraded to the full radius.
        var store = placeStores[storeKey] ?? PlaceStore();
        store.merge(items);
        store.recordCoverage(radius: requestRadius, complete: false);
        placeStores[storeKey] = store;

        guard gen == generation else {
            print("[TourListVM] page \(items.isEmpty ? -1 : 0) (gen \(gen)) superseded by gen \(generation) — merged into store only");
            return;
        };

        infos.append(contentsOf: items);
        totalCount     = total;
        isFetchingNext = false;
        print("[TourListVM] page loaded — items: \(items.count), infos: \(infos.count)/\(totalCount), hasMorePages: \(hasMorePages)");

        if hasMorePages {
            if continueChain {
                fetchAllPages();
            }
        } else {
            // This generation's chain is fully loaded — now it's safe to
            // claim the full requested radius.
            var completedStore = placeStores[storeKey] ?? PlaceStore();
            completedStore.recordCoverage(radius: requestRadius, complete: true);
            placeStores[storeKey] = completedStore;
            lastRequest = nil;
        }
    }

    func refresh() async {
        guard let loc = location else { return };
        let storeKey = PlaceStoreKey(location: loc, type: selectedType);
        placeStores.removeValue(forKey: storeKey);
        fetchList();
    }
}
