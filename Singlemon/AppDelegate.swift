//
//  AppDelegate.swift
//  Singlemon
//
//  Created by Nic on 2025-12-23.
//

import AppKit
import Combine
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let controller = MouseWallController()
    private var cancellables = Set<AnyCancellable>()
    private var toggleItem: NSMenuItem?
    private var authorizeItem: NSMenuItem?
    private var authorizeSeparator: NSMenuItem?
    private var toggleSeparator: NSMenuItem?
    private var statusMenu: NSMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerLoginItem()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let image = NSImage(named: "menu_bar_icon") {
                image.isTemplate = true
                let maxHeight = (NSStatusBar.system.thickness - 4) * 0.9
                if maxHeight > 0 {
                    let scale = maxHeight / image.size.height
                    image.size = NSSize(width: image.size.width * scale, height: maxHeight)
                }
                button.image = image
            }
        }

        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Turn On", action: #selector(toggleWall(_:)), keyEquivalent: "")
        toggleItem.target = self
        let toggleSeparator = NSMenuItem.separator()
        menu.addItem(toggleItem)
        menu.addItem(toggleSeparator)
        let quitItem = NSMenuItem(title: "Quit Singlemon", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.menu = menu
        statusMenu = menu
        self.toggleItem = toggleItem
        self.toggleSeparator = toggleSeparator
        let authorizeItem = NSMenuItem(title: "Authorize Singlemon", action: #selector(authorizeAccessibility(_:)), keyEquivalent: "")
        authorizeItem.target = self
        self.authorizeItem = authorizeItem
        authorizeSeparator = .separator()

        controller.start()

        controller.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] isEnabled in
                self?.toggleItem?.title = isEnabled ? "Turn Off" : "Turn On"
                self?.updateStatusIconOpacity()
            }
            .store(in: &cancellables)

        controller.$hasAccessibilityAccess
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuForAccess()
                self?.updateStatusIconOpacity()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshAccessAndMenu()
            }
            .store(in: &cancellables)

        refreshAccessAndMenu()
    }

    @objc private func toggleWall(_ sender: Any?) {
        controller.toggle()
    }

    @objc private func authorizeAccessibility(_ sender: Any?) {
        controller.requestAccessibilityAccess()
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }

    private func refreshAccessAndMenu() {
        controller.refreshAccessibilityStatus()
        updateMenuForAccess()
        updateStatusIconOpacity()
    }

    private func updateMenuForAccess() {
        guard let menu = statusMenu,
              let toggleItem,
              let authorizeItem,
              let authorizeSeparator,
              let toggleSeparator else { return }

        let hasAccess = controller.hasAccessibilityAccess
        if !hasAccess && controller.isEnabled {
            controller.stop()
        }
        toggleItem.isEnabled = hasAccess

        if hasAccess {
            if menu.items.contains(authorizeItem) {
                menu.removeItem(authorizeItem)
            }
            if menu.items.contains(authorizeSeparator) {
                menu.removeItem(authorizeSeparator)
            }
            if !menu.items.contains(toggleItem) {
                menu.insertItem(toggleItem, at: 0)
                menu.insertItem(toggleSeparator, at: 1)
            }
        } else if !menu.items.contains(authorizeItem) {
            menu.insertItem(authorizeItem, at: 0)
            menu.insertItem(authorizeSeparator, at: 1)
            if menu.items.contains(toggleItem) {
                menu.removeItem(toggleItem)
            }
            if menu.items.contains(toggleSeparator) {
                menu.removeItem(toggleSeparator)
            }
        }
    }

    private func updateStatusIconOpacity() {
        guard let button = statusItem?.button else { return }
        if controller.hasAccessibilityAccess {
            button.alphaValue = controller.isEnabled ? 1.0 : 0.5
        } else {
            button.alphaValue = 0.35
        }
    }

    private func registerLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                NSLog("Singlemon: Failed to register login item: \(error)")
            }
        }
    }
}
