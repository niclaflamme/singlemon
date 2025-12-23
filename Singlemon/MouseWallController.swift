//
//  MouseWallController.swift
//  Singlemon
//
//  Created by Nic on 2025-12-23.
//

import AppKit
import ApplicationServices
import Combine

@MainActor
final class MouseWallController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var hasAccessibilityAccess = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var mainBounds = CGRect.zero

    init() {
        updateMainBounds()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func start() {
        refreshAccessibilityStatus()
        guard hasAccessibilityAccess else { return }
        guard !isEnabled else { return }

        updateMainBounds()
        if !mainBounds.contains(currentMouseLocation()) {
            warpToMainCenter()
        }

        let mask = (1 << CGEventType.mouseMoved.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.rightMouseDragged.rawValue)
            | (1 << CGEventType.otherMouseDragged.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passRetained(event) }
            let controller = Unmanaged<MouseWallController>.fromOpaque(refcon).takeUnretainedValue()

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let eventTap = controller.eventTap {
                    CGEvent.tapEnable(tap: eventTap, enable: true)
                }
                return Unmanaged.passRetained(event)
            }

            if type == .mouseMoved || type == .leftMouseDragged || type == .rightMouseDragged || type == .otherMouseDragged {
                controller.clamp(event: event)
            }

            return Unmanaged.passRetained(event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: refcon
        )

        guard let eventTap else {
            isEnabled = false
            return
        }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isEnabled = true
        }
    }

    func stop() {
        guard isEnabled else { return }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
        isEnabled = false
    }

    func toggle() {
        isEnabled ? stop() : start()
    }

    func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        refreshAccessibilityStatus()
    }

    func refreshAccessibilityStatus() {
        hasAccessibilityAccess = AXIsProcessTrusted()
    }

    private func clamp(event: CGEvent) {
        let location = event.location
        let clamped = CGPoint(
            x: min(max(location.x, mainBounds.minX), mainBounds.maxX - 1),
            y: min(max(location.y, mainBounds.minY), mainBounds.maxY - 1)
        )

        if location != clamped {
            event.location = clamped
        }
    }

    private func currentMouseLocation() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    private func warpToMainCenter() {
        let center = CGPoint(x: mainBounds.midX, y: mainBounds.midY)
        CGWarpMouseCursorPosition(center)
        CGAssociateMouseAndMouseCursorPosition(1)
    }

    private func updateMainBounds() {
        mainBounds = CGDisplayBounds(CGMainDisplayID())
    }

    @objc private func handleScreenChange() {
        updateMainBounds()
    }
}
