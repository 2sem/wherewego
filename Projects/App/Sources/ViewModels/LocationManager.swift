import Foundation
import CoreLocation
import Observation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocationCoordinate2D? = nil;
    var authorizationStatus: CLAuthorizationStatus = .notDetermined;
    /// True while a `requestLocation()` call is in flight. Drives the location
    /// button's spinner/disabled state so a slow fix gives visible feedback.
    var isLocating: Bool = false;
    /// Bumped every time `didFailWithError` fires. A counter (rather than a
    /// Bool) so consecutive failures each produce a distinct change for
    /// `.onChange(of:)` to observe, even if a view never resets it.
    var locationErrorCount: Int = 0;

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
        isLocating = true;
        clManager.requestLocation();
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLocating = false;
        guard let coord = locations.first?.coordinate else { return };
        currentLocation = coord;
        manager.stopUpdatingLocation();
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false;
        locationErrorCount += 1;
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
