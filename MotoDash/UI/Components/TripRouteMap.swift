import MapKit
import SwiftUI
import UIKit

/// Route map via Apple's native MapKit (free, no API key) -- the Kotlin source
/// uses OSMdroid (OpenStreetMap tiles); MapKit is the better platform fit here,
/// not a compromise. Same visual intent: cyan route line, start/finish markers.
struct TripRouteMap: UIViewRepresentable {
    let points: [RoutePoint]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        guard points.count >= 2 else { return }

        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        let coordinates = points.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)

        let start = MKPointAnnotation()
        start.coordinate = coordinates[0]
        start.title = "Start"
        mapView.addAnnotation(start)

        let finish = MKPointAnnotation()
        finish.coordinate = coordinates[coordinates.count - 1]
        finish.title = "Finish"
        mapView.addAnnotation(finish)

        var boundingRect = MKMapRect.null
        for coordinate in coordinates {
            let point = MKMapPoint(coordinate)
            boundingRect = boundingRect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
        mapView.setVisibleMapRect(
            boundingRect,
            edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
            animated: false
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.cyan
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
