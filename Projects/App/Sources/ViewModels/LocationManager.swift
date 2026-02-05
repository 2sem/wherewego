import Foundation
import CoreLocation
import Observation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocationCoordinate2D? = nil;
    var authorizationStatus: CLAuthorizationStatus = .notDetermined;

    private let clManager = CLLocationManager();

    override init() {
        super.init();
        clManager.delegate = self;
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        clManager.distanceFilter = 500;
    }

    func requestAuthorization() {
        clManager.requestWhenInUseAuthorization();
    }

    func requestLocation() {
        clManager.requestLocation();
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else { return };
        currentLocation = coord;
        manager.stopUpdatingLocation();
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error)");
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus;
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation();
        case .denied:
            break;
        default:
            break;
        }
    }
}
