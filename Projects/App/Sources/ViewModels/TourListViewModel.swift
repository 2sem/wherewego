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

    /// True once pagination for the *current* area stopped early because it
    /// hit `maxPlacesPerArea`, even though more pages remained on the server.
    /// Folded into `hasMorePages` so the "loading more" badge doesn't spin
    /// forever once capped.
    private var isCapped: Bool = false;

    var hasMorePages: Bool { !isCapped && totalCount > 0 && infos.count < totalCount; }

    /// The radius, from the current search center, that we actually have
    /// *complete* data for — unlike `radius`, which is merely what was
    /// requested. A drag/zoom should only skip refetching when the newly
    /// visible area is inside this, not the requested `radius`: a fetch
    /// that got capped at `maxPlacesPerArea` in a dense area (e.g. Seoul)
    /// may have only reached 2-3km even though 15km was requested, and
    /// claiming the full 15km there is exactly the false "nothing here"
    /// bug this exists to prevent.
    ///
    /// - A fetch that completes in full (never hit the cap) → `radius`.
    /// - A fetch that hit `maxPlacesPerArea`, or is still mid-`fetchAllPages`
    ///   pagination → the farthest loaded item's distance, which grows as
    ///   each further page is merged in.
    /// - A fresh network fetch with nothing loaded yet for the current
    ///   generation → 0 — never claim coverage that isn't loaded.
    /// - A cache hit → `radius` (the store already guarantees
    ///   `maxFetchedRadius >= requestRadius`, i.e. genuinely complete).
    ///
    /// Only ever written by a callback whose captured generation still
    /// matches `requestGeneration`, same as every other piece of visible
    /// state.
    private(set) var coveredRadius: Int = 0;

    private var lastRequest: KGDataTourListRequest? = nil;
    private var isFetchingNext: Bool = false;
    private var placeStores: [PlaceStoreKey: PlaceStore] = [:];

    /// Bumped at the start of every `fetchList()` call — both the cache-hit
    /// and network paths. Every in-flight callback (first page, next page,
    /// fetchAllPages) captures the generation, location, radius and store
    /// key it was issued under at request time, and never reads `self.*`
    /// for those values later. Only a callback whose captured generation
    /// still matches `requestGeneration` when it returns is allowed to
    /// touch visible state (`infos`, `totalCount`, `isLoading`,
    /// `isFetchingNext`, `isCapped`) or continue its own pagination chain.
    /// A superseded callback still merges its items into the place-store
    /// cache for ITS OWN captured key — valid data for that area, so
    /// dragging back to it later is instant — but stops there.
    private var requestGeneration: Int = 0;

    /// Hard cap on places loaded per area. Results are distance-sorted
    /// (`arrange=E`), so this always keeps the nearest N. Without it,
    /// fetch-on-drop can chain 10+ sequential page requests over a dense
    /// area like Seoul (100 rows/page, up to a 20km radius).
    private let maxPlacesPerArea = 300;

    func fetchList() {
        guard let loc = location else { return };

        requestGeneration += 1;
        let generation = requestGeneration;
        let storeKey = PlaceStoreKey(location: loc, type: selectedType);
        let requestRadius = radius;

        if let store = placeStores[storeKey], !store.isStale, store.maxFetchedRadius >= requestRadius {
            let filtered = store.filtered(within: requestRadius, from: loc);
            infos          = filtered;
            totalCount     = filtered.count;   // hasMorePages = false → load-more disabled
            isCapped       = false;
            isLoading      = false;
            coveredRadius  = requestRadius;    // store.maxFetchedRadius >= requestRadius already guarantees this
            lastRequest    = nil;
            isFetchingNext = false;
            print("[TourListVM] store hit — \(filtered.count) items (store has \(store.places.count), maxR: \(store.maxFetchedRadius))");
            return;
        }

        isLoading      = true;
        isCapped       = false;
        coveredRadius  = 0;    // nothing loaded yet for this generation
        // NOTE: infos NOT cleared — old results stay visible during network load
        totalCount     = 0;
        lastRequest    = nil;
        isFetchingNext = false;

        print("[TourListVM] fetchList() network call — radius: \(requestRadius), gen: \(generation)");
        lastRequest = KGDataTourManager.shared.requestList(
            type: selectedType,
            location: loc,
            radius: UInt(requestRadius)
        ) { [weak self] (page, items, total, error) in
            guard let self = self else { return };
            DispatchQueue.main.async {
                self.handleFirstPage(generation: generation, storeKey: storeKey, requestRadius: requestRadius, page: page, items: items, total: total);
            }
        };
    }

    private func handleFirstPage(generation: Int, storeKey: PlaceStoreKey, requestRadius: Int, page: Int, items: [KGDataTourInfo], total: Int) {
        mergeIntoStore(storeKey: storeKey, items: items, requestRadius: requestRadius);

        guard generation == requestGeneration else {
            print("[TourListVM] page \(page) (gen \(generation)) superseded by gen \(requestGeneration) — cached \(items.count) items for its own area only");
            return;
        }

        totalCount = total;
        infos      = items;
        isLoading  = false;
        if infos.count >= maxPlacesPerArea && infos.count < total {
            isCapped      = true;
            coveredRadius = min(requestRadius, farthestDistance(in: items));
        } else if infos.count >= total {
            coveredRadius = requestRadius;    // the whole area landed in one page
        } else {
            coveredRadius = min(requestRadius, farthestDistance(in: items));    // more pages still coming
        }
        print("[TourListVM] page \(page) loaded — items: \(items.count), total: \(total), hasMorePages: \(hasMorePages), coveredRadius: \(coveredRadius)");
    }

    func fetchNextPage() {
        guard !isFetchingNext, let next = lastRequest?.next, let loc = location else { return };
        let generation = requestGeneration;
        let storeKey = PlaceStoreKey(location: loc, type: selectedType);
        let requestRadius = radius;
        isFetchingNext = true;
        lastRequest = next;

        KGDataTourManager.shared.requestList(request: next) { [weak self] (page, items, total, error) in
            guard let self = self else { return };
            DispatchQueue.main.async {
                self.mergeIntoStore(storeKey: storeKey, items: items, requestRadius: requestRadius);
                guard generation == self.requestGeneration else {
                    print("[TourListVM] fetchNextPage page \(page) (gen \(generation)) superseded by gen \(self.requestGeneration) — cached only");
                    return;
                };
                self.infos.append(contentsOf: items);
                self.isFetchingNext = false;
                if self.infos.count >= self.totalCount {
                    self.coveredRadius = requestRadius;
                } else {
                    self.coveredRadius = max(self.coveredRadius, min(requestRadius, self.farthestDistance(in: items)));
                }
            }
        };
    }

    func fetchAllPages() {
        print("[TourListVM] fetchAllPages() called — isFetchingNext: \(isFetchingNext), hasMorePages: \(hasMorePages), lastRequest.page: \(lastRequest?.page ?? -1)");
        guard !isFetchingNext, hasMorePages, let next = lastRequest?.next, let loc = location else {
            print("[TourListVM] fetchAllPages() guard failed — isFetchingNext: \(isFetchingNext), hasMorePages: \(hasMorePages), lastRequest: \(lastRequest == nil ? "nil" : "page \(lastRequest!.page)")");
            return;
        };

        let generation = requestGeneration;
        let storeKey = PlaceStoreKey(location: loc, type: selectedType);
        let requestRadius = radius;
        isFetchingNext = true;
        lastRequest = next;
        print("[TourListVM] fetching page \(next.page)...");

        KGDataTourManager.shared.requestList(request: next) { [weak self] (page, items, total, error) in
            guard let self = self else { return };
            DispatchQueue.main.async {
                self.handleAllPagesResponse(generation: generation, storeKey: storeKey, requestRadius: requestRadius, page: page, items: items);
            }
        };
    }

    private func handleAllPagesResponse(generation: Int, storeKey: PlaceStoreKey, requestRadius: Int, page: Int, items: [KGDataTourInfo]) {
        mergeIntoStore(storeKey: storeKey, items: items, requestRadius: requestRadius);

        guard generation == requestGeneration else {
            print("[TourListVM] fetchAllPages page \(page) (gen \(generation)) superseded by gen \(requestGeneration) — cached \(items.count) items for its own area only");
            return;
        }

        infos.append(contentsOf: items);
        isFetchingNext = false;
        if infos.count >= maxPlacesPerArea && infos.count < totalCount {
            isCapped      = true;
            coveredRadius = max(coveredRadius, min(requestRadius, farthestDistance(in: items)));
        } else if infos.count >= totalCount {
            coveredRadius = requestRadius;    // pagination genuinely exhausted, not just capped
        } else {
            coveredRadius = max(coveredRadius, min(requestRadius, farthestDistance(in: items)));    // grows as more pages arrive
        }
        print("[TourListVM] fetchAllPages page \(page) loaded — items: \(infos.count)/\(totalCount), hasMorePages: \(hasMorePages), capped: \(isCapped), coveredRadius: \(coveredRadius)");

        if hasMorePages {
            fetchAllPages();
        }
    }

    /// The farthest distance (API `dist`, relative to the request's own
    /// search center) among a batch of items — used both to grow the
    /// view model's live `coveredRadius` and the place-store's persisted
    /// `maxFetchedRadius` claim as pages arrive.
    private func farthestDistance(in items: [KGDataTourInfo]) -> Int {
        items.compactMap { $0.distance }.max() ?? 0;
    }

    /// Merges a batch into the place-store cache for `storeKey` and updates
    /// its coverage claim. The claim is always `min(requestRadius,
    /// farthestItemDistance)` — never the bare requested radius — so a
    /// chain that got capped at 300 or abandoned mid-pagination (superseded
    /// by a newer drag) can never claim coverage further out than what was
    /// actually loaded. Results are distance-sorted (`arrange=E`) and pages
    /// are always merged in increasing-page order for a given request, so
    /// the claim only ever grows monotonically as farther pages come in.
    /// This slightly under-claims a fully-completed fetch when there's
    /// simply nothing near the requested edge (an extra, harmless refetch
    /// later) — the safe tradeoff versus ever over-claiming and bringing
    /// back a false "nothing here".
    private func mergeIntoStore(storeKey: PlaceStoreKey, items: [KGDataTourInfo], requestRadius: Int) {
        var store = placeStores[storeKey] ?? PlaceStore();
        store.merge(items);
        store.maxFetchedRadius = max(store.maxFetchedRadius, min(requestRadius, farthestDistance(in: items)));
        placeStores[storeKey] = store;
    }

    func refresh() async {
        guard let loc = location else { return };
        let storeKey = PlaceStoreKey(location: loc, type: selectedType);
        placeStores.removeValue(forKey: storeKey);
        fetchList();
    }
}
