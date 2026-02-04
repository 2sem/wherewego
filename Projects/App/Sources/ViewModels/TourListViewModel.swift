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

    private var lastRequest: KGDataTourListRequest? = nil;
    private var isFetchingNext: Bool = false;

    func fetchList() {
        guard let loc = location else { return };

        isLoading = true;
        infos.removeAll();
        lastRequest = nil;
        isFetchingNext = false;

        lastRequest = KGDataTourManager.shared.requestList(
            type: selectedType,
            location: loc,
            radius: UInt(radius)
        ) { [weak self] (page, items, total, error) in
            guard let self = self else { return };
            DispatchQueue.main.async {
                self.infos.append(contentsOf: items);
                self.isLoading = false;
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

    func refresh() async {
        fetchList();
    }
}
