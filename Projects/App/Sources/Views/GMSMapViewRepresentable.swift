import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Configuration types

struct MapMarkerConfig {
    let position: CLLocationCoordinate2D;
    let title: String;
    let color: UIColor;
    let isDraggable: Bool;
}

struct MapCircleConfig {
    let position: CLLocationCoordinate2D;
    let radius: CLLocationDistance;
    let fillColor: UIColor;
}

// MARK: - UIViewRepresentable

struct GMSMapViewRepresentable: UIViewRepresentable {
    let initialCamera: GMSCameraPosition?
    var markers: [MapMarkerConfig]
    var circle: MapCircleConfig?
    var fitBounds: GMSCoordinateBounds?
    var isMyLocationEnabled: Bool = false
    var myLocationButtonEnabled: Bool = false
    var onMarkerDragEnd: ((CLLocationCoordinate2D) -> Void)?

    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView();
        if let cam = initialCamera {
            mapView.camera = cam;
        }
        mapView.isMyLocationEnabled = isMyLocationEnabled;
        mapView.settings.myLocationButton = myLocationButtonEnabled;
        mapView.delegate = context.coordinator;
        context.coordinator.mapView = mapView;
        applyMarkers(mapView, context: context);
        applyCircle(mapView, context: context);
        applyFitBounds(mapView);
        return mapView;
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Clear old markers
        context.coordinator.markers.forEach { $0.map = nil };
        context.coordinator.markers.removeAll();
        context.coordinator.circle?.map = nil;
        context.coordinator.circle = nil;

        applyMarkers(mapView, context: context);
        applyCircle(mapView, context: context);
        applyFitBounds(mapView);
    }

    private func applyMarkers(_ mapView: GMSMapView, context: Context) {
        for cfg in markers {
            let marker = GMSMarker(position: cfg.position);
            marker.title = cfg.title;
            marker.icon = GMSMarker.markerImage(with: cfg.color);
            marker.isDraggable = cfg.isDraggable;
            marker.map = mapView;
            context.coordinator.markers.append(marker);
        }
    }

    private func applyCircle(_ mapView: GMSMapView, context: Context) {
        guard let cfg = circle else { return };
        let gmsCircle = GMSCircle(position: cfg.position, radius: cfg.radius);
        gmsCircle.fillColor = cfg.fillColor;
        gmsCircle.map = mapView;
        context.coordinator.circle = gmsCircle;
    }

    private func applyFitBounds(_ mapView: GMSMapView) {
        guard let bounds = fitBounds else { return };
        let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets(top: 44, left: 44, bottom: 44, right: 44));
        mapView.animate(with: update);
    }

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(onMarkerDragEnd: onMarkerDragEnd);
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var markers: [GMSMarker] = [];
        var circle: GMSCircle? = nil;
        weak var mapView: GMSMapView? = nil;
        let onMarkerDragEnd: ((CLLocationCoordinate2D) -> Void)?

        init(onMarkerDragEnd: ((CLLocationCoordinate2D) -> Void)?) {
            self.onMarkerDragEnd = onMarkerDragEnd;
        }

        func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
            onMarkerDragEnd?(marker.position);
        }
    }
}
