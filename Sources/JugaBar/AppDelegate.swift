import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 1. Create the Popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        self.popover = popover
        
        // 2. Create the Status Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "JugaBar")
            button.action = #selector(mouseClickHandler)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func mouseClickHandler() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "About JugaBar", action: #selector(showAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
            
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePopover(statusItem.button)
        }
    }
    
    func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                closePopover(sender)
            } else {
                showPopover(button)
            }
        }
    }
    
    func showPopover(_ sender: NSStatusBarButton) {
        NotificationCenter.default.post(name: .resetUI, object: nil)
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        
        // Start monitoring for outside clicks
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover(nil)
        }
    }
    
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        // Stop monitoring
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}