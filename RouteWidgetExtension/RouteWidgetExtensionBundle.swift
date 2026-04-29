//
//  RouteWidgetExtensionBundle.swift
//  RouteWidgetExtensionExtension
//
//  Created by José Ruiz on 28/4/26.
//

import Foundation
import WidgetKit
import SwiftUI

@main
@available(iOS 16.2, *)
struct RouteWidgetBundle: WidgetBundle {
    var body: some Widget {
        RouteWidgetExtension()
        if #available(iOSApplicationExtension 16.2, *) {
            RouteLiveActivityWidget()
        }
        RouteWidgetExtensionControl()
    }
}
