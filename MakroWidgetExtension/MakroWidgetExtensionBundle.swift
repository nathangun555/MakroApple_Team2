//
//  MakroWidgetExtensionBundle.swift
//  MakroWidgetExtension
//
//  Created by Edward Suwandi on 20/11/25.
//

import WidgetKit
import SwiftUI

@main
struct MakroWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        MakroWidgetExtension()
        MakroWidgetExtensionControl()
    }
}
