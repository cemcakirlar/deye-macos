import AppKit
import SwiftUI

@MainActor
public final class WindowManager: NSObject, NSWindowDelegate {
    public static let shared = WindowManager()

    public weak var mainWindow: NSWindow?
    public weak var appState: AppState?
    public var isTerminating: Bool = false

    private var hasAppliedStartupVisibility: Bool = false
    private let delegateProxy = MainWindowDelegateProxy()

    private override init() {
        super.init()
        delegateProxy.owner = self
    }

    public func register(window: NSWindow, appState: AppState) {
        let isMainWindow = window.identifier?.rawValue == "main" || window.title == "Deye Solar Monitor"
        guard isMainWindow else { return }

        mainWindow = window
        self.appState = appState
        window.isReleasedWhenClosed = false

        if window.delegate !== delegateProxy {
            delegateProxy.forwarded = window.delegate
            window.delegate = delegateProxy
        }

        guard !hasAppliedStartupVisibility else { return }
        hasAppliedStartupVisibility = true

        guard appState.showMainWindowOnLaunch == false else { return }
        window.alphaValue = 0
        window.orderOut(nil)
        window.alphaValue = 1
    }

    public func showMainWindow() {
        let window = resolvedMainWindow()
        if let window {
            mainWindow = window
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    public func hideMainWindow() {
        mainWindow?.orderOut(nil)
    }

    public func toggleMainWindow() {
        if let window = resolvedMainWindow(), window.isVisible, !window.isMiniaturized {
            window.orderOut(nil)
        } else {
            showMainWindow()
        }
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isTerminating {
            return true
        }
        sender.orderOut(nil)
        return false
    }

    private func resolvedMainWindow() -> NSWindow? {
        if let mainWindow {
            return mainWindow
        }
        return NSApp.windows.first { window in
            window.identifier?.rawValue == "main" || window.title == "Deye Solar Monitor"
        }
    }
}

@MainActor
private final class MainWindowDelegateProxy: NSObject, NSWindowDelegate {
    weak var owner: WindowManager?
    weak var forwarded: NSWindowDelegate?

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        owner?.windowShouldClose(sender) ?? true
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        return forwarded?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) {
            return nil
        }
        if let forwarded, forwarded.responds(to: aSelector) {
            return forwarded
        }
        return super.forwardingTarget(for: aSelector)
    }
}

public struct WindowAccessor: NSViewRepresentable {
    private let onResolve: (NSWindow) -> Void

    public init(onResolve: @escaping (NSWindow) -> Void) {
        self.onResolve = onResolve
    }

    public func makeNSView(context: Context) -> WindowObserverView {
        let view = WindowObserverView()
        view.onResolve = onResolve
        return view
    }

    public func updateNSView(_ nsView: WindowObserverView, context: Context) {
        nsView.onResolve = onResolve
    }
}

public final class WindowObserverView: NSView {
    var onResolve: ((NSWindow) -> Void)?

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        onResolve?(window)
    }
}
