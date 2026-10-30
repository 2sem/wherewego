import XCTest
import CoreLocation
import MapKit
@testable import App

final class NearbyPlacesFilterTests: XCTestCase {
    private let center = CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0);
    private lazy var region = MKCoordinateRegion(
        center: center,
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    );

    private func place(_ id: Int, lat: Double, lon: Double, dist: Int? = nil) -> KGDataTourInfo {
        var json: [String: AnyObject] = [
            KGDataTourInfo.fieldNames.id: id as AnyObject,
            KGDataTourInfo.fieldNames.latitude: lat as AnyObject,
            KGDataTourInfo.fieldNames.longitude: lon as AnyObject,
        ];
        if let dist = dist { json[KGDataTourInfo.fieldNames.distance] = dist as AnyObject; }
        return KGDataTourInfo(json);
    }

    func test_filtersToRegion() {
        let inside = place(1, lat: 37.505, lon: 127.005);
        let outside = place(2, lat: 37.6, lon: 127.0);
        let result = NearbyPlacesFilter.make(infos: [inside, outside], region: region, selected: nil, origin: center);
        XCTAssertEqual(result.places.map(\.id), [1]);
        XCTAssertEqual(result.totalCount, 1);
    }

    func test_nilRegionKeepsEverything() {
        let result = NearbyPlacesFilter.make(
            infos: [place(1, lat: 37.5, lon: 127.0), place(2, lat: 38.5, lon: 128.0)],
            region: nil, selected: nil, origin: center
        );
        XCTAssertEqual(result.places.count, 2);
    }

    func test_sortsByDistanceFromOrigin() {
        let far = place(1, lat: 37.508, lon: 127.0);
        let near = place(2, lat: 37.501, lon: 127.0);
        let mid = place(3, lat: 37.504, lon: 127.0);
        let result = NearbyPlacesFilter.make(infos: [far, near, mid], region: region, selected: nil, origin: center);
        XCTAssertEqual(result.places.map(\.id), [2, 3, 1]);
        XCTAssertEqual(result.places.first?.distance.map { $0 < 200 }, true);
    }

    func test_sameDistanceBreaksTieById() {
        let a = place(9, lat: 37.501, lon: 127.0);
        let b = place(4, lat: 37.501, lon: 127.0);
        let result = NearbyPlacesFilter.make(infos: [a, b], region: region, selected: nil, origin: center);
        XCTAssertEqual(result.places.map(\.id), [4, 9]);
    }

    func test_selectedOutsideRegionKeepsDistanceSlot() {
        let inside = place(1, lat: 37.501, lon: 127.0);
        let selected = place(2, lat: 37.9, lon: 127.0);
        let result = NearbyPlacesFilter.make(infos: [inside, selected], region: region, selected: selected, origin: center);
        XCTAssertEqual(result.places.map(\.id), [1, 2]);
        XCTAssertEqual(result.totalCount, 2);
    }

    func test_selectedInsideRegionIsNotDuplicated() {
        let selected = place(1, lat: 37.505, lon: 127.0);
        let other = place(2, lat: 37.501, lon: 127.0);
        let result = NearbyPlacesFilter.make(infos: [other, selected], region: region, selected: selected, origin: center);
        XCTAssertEqual(result.places.map(\.id), [2, 1]);
        XCTAssertEqual(result.totalCount, 2);
    }

    func test_capKeepsNearestAndFlagsTruncation() {
        let infos = (1...10).map { place($0, lat: 37.5 + Double($0) * 0.0005, lon: 127.0) };
        let selected = place(99, lat: 37.9, lon: 127.0);
        let result = NearbyPlacesFilter.make(infos: infos, region: region, selected: selected, origin: center, limit: 3);
        XCTAssertEqual(result.places.map(\.id), [1, 2, 3, 99]);
        XCTAssertTrue(result.isTruncated);
        XCTAssertEqual(result.totalCount, 11);
    }

    func test_dropsDuplicatesAndPlacesWithoutIdOrLocation() {
        let noId = KGDataTourInfo([
            KGDataTourInfo.fieldNames.latitude: 37.5 as AnyObject,
            KGDataTourInfo.fieldNames.longitude: 127.0 as AnyObject,
        ]);
        let noLocation = KGDataTourInfo([KGDataTourInfo.fieldNames.id: 5 as AnyObject]);
        let dup = place(1, lat: 37.5, lon: 127.0);
        let result = NearbyPlacesFilter.make(infos: [dup, dup, noId, noLocation], region: region, selected: nil, origin: center);
        XCTAssertEqual(result.places.map(\.id), [1]);
    }

    func test_withoutOriginFallsBackToApiDistance() {
        let a = place(1, lat: 37.5, lon: 127.0, dist: 500);
        let b = place(2, lat: 37.5, lon: 127.0, dist: 100);
        let result = NearbyPlacesFilter.make(infos: [a, b], region: nil, selected: nil, origin: nil);
        XCTAssertEqual(result.places.map(\.id), [2, 1]);
        XCTAssertEqual(result.places.first?.distance, 100);
    }
}
