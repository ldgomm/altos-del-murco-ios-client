//
//  RouteDeepLink.swift
//  Altos del Murco
//
//  Created by José Ruiz on 29/4/26.
//

import Foundation

enum RouteDeepLink {
    static let scheme = "altosdelmurco"
    static let routeHost = "route"
    static let directionsPath = "/directions"

    static var directionsURL: URL {
        URL(string: "\(scheme)://\(routeHost)\(directionsPath)")!
    }

    static func isDirectionsURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == scheme else {
            return false
        }

        let host = url.host?.lowercased()
        let path = url.path.lowercased()

        return (host == routeHost && path == directionsPath)
            || host == "directions"
    }
}
