import Foundation
import CoreLocation
import Observation

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

    func fetchList() {
        guard let loc = location else { return };

        isLoading = true;
        infos.removeAll();
        totalCount = 0;
        lastRequest = nil;
        isFetchingNext = false;

        print("[TourListVM] fetchList() started");
        lastRequest = KGDataTourManager.shared.requestList(
            type: selectedType,
            location: loc,
            radius: UInt(radius)
        ) { [weak self] (page, items, total, error) in
            guard let self = self else { return };
            DispatchQueue.main.async {
                self.totalCount = total;
                self.infos.append(contentsOf: items);
                self.isLoading = false;
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
                if self.hasMorePages {
                    self.fetchAllPages();
                }
            }
        };
    }

    func refresh() async {
        fetchList();
    }
}
