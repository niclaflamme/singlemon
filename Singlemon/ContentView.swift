//
//  ContentView.swift
//  Singlemon
//
//  Created by Nic on 2025-12-23.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var controller: MouseWallController
    @State private var showingAccessibilityAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if controller.hasAccessibilityAccess {
                Text("Menu bar app is running.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                Toggle(isOn: Binding(
                    get: { controller.isEnabled },
                    set: { _ in controller.toggle() }
                )) {
                    Text(controller.isEnabled ? "Wall enabled" : "Wall disabled")
                }
            } else {
                Divider()
                MissingPermissionsView {
                    controller.requestAccessibilityAccess()
                    showingAccessibilityAlert = true
                }
            }

            HStack {
                Button("Quit Singlemon") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding()
        .alert("Enable Accessibility Access", isPresented: $showingAccessibilityAlert) {
            Button("Open System Settings") {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                if let url {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Turn on Singlemon in Privacy & Security → Accessibility, then relaunch the app.")
        }
    }
}

#Preview("Missing Permissions") {
    MissingPermissionsView(onOpenSettings: {})
        .padding()
}

private struct MissingPermissionsView: View {
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Permissions Required")
                .font(.headline)

            Text("Singlemon needs Accessibility access to control the mouse. Until it is granted, the wall cannot be enabled.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Open Accessibility Settings") {
                    onOpenSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.quaternary)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#Preview {
    ContentView()
}
