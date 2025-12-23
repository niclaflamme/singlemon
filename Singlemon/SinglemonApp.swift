//
//  SinglemonApp.swift
//  Singlemon
//
//  Created by Nic on 2025-12-23.
//

import SwiftUI

@main
struct SinglemonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
