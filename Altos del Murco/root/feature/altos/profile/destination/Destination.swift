//
//  Destination.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
//

import CoreLocation
import Foundation
import MapKit

enum Destination {
    /// Default pin based on the El Murco / Tambillo public map coordinate.
    /// Replace these coordinates with the exact restaurant gate/parking entrance if your final pin differs.
    static let name = "Altos del Murco"
    static let subtitle = "El Murco, Tambillo, Mejía, Pichincha"
    static let address = "Sector El Murco, Tambillo, Mejía, Pichincha, Ecuador"
    static let phoneDisplay = "WhatsApp Altos del Murco"

    static let coordinate = CLLocationCoordinate2D(
        latitude: -0.43318,
        longitude: -78.54025
    )

    static var location: CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    static var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        return item
    }

    static var cameraRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
    }
}
