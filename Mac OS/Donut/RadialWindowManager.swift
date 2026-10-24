import AppKit
import SwiftUI

final class RadialWindowManager: NSObject {
    private var panel: NSPanel?
    private var eventMonitorTokens: [Any] = []
    private var isDragging = false
    private var isShiftPressed = false
    private var pendingHide: DispatchWorkItem?
    private var pendingPositionUpdate: DispatchWorkItem?
    private var pendingScreenPoint: NSPoint?
    private var isShowingPanel = false
    private var lastEventTimestamp: TimeInterval = 0
    private var lastEventLocation = NSPoint.zero
    private var conversionTask: Task<Void, Never>?
    private var conversionID = UUID()
    private let hudModel = RadialHUDModel()
    private let converter = FileConverter()

    func startMonitoring() {
        guard eventMonitorTokens.isEmpty else { return }

        let events: NSEvent.EventTypeMask = [.flagsChanged, .leftMouseDragged, .leftMouseUp]
        if let token = NSEvent.addGlobalMonitorForEvents(matching: events, handler: { [weak self] event in
            self?.handle(event: event)
        }) {
            eventMonitorTokens.append(token)
        }

        if let token = NSEvent.addLocalMonitorForEvents(matching: events, handler: { [weak self] event in
            self?.handle(event: event)
            return event
        }) {
            eventMonitorTokens.append(token)
        }
    }

    func stopMonitoring() {
        eventMonitorTokens.forEach { token in
            NSEvent.removeMonitor(token)
        }
        eventMonitorTokens.removeAll()
        pendingHide?.cancel()
        pendingHide = nil
        pendingPositionUpdate?.cancel()
        pendingPositionUpdate = nil
        pendingScreenPoint = nil
        conversionTask?.cancel()
        conversionTask = nil
        conversionID = UUID()
        lastEventTimestamp = 0
        lastEventLocation = .zero
        hidePanel()
        isDragging = false
        isShiftPressed = false
    }

    private func handle(event: NSEvent) {
        let location = NSEvent.mouseLocation
        let isDuplicate = event.timestamp == lastEventTimestamp
            && location == lastEventLocation

        if isDuplicate {
            return
        }

        lastEventTimestamp = event.timestamp
        lastEventLocation = location

        switch event.type {
        case .leftMouseDragged:
            pendingHide?.cancel()
            pendingHide = nil
            isDragging = true
            isShiftPressed = event.modifierFlags.contains(.shift)
            if isShiftPressed && !isShowingPanel {
                requestPanelPosition(location)
            } else {
                if !isShiftPressed {
                    hidePanel()
                }
            }
        case .flagsChanged:
            isShiftPressed = event.modifierFlags.contains(.shift)
            if isDragging && isShiftPressed && !isShowingPanel {
                pendingHide?.cancel()
                pendingHide = nil
                requestPanelPosition(location)
            } else if !isShiftPressed {
                hidePanel()
            }
        case .leftMouseUp:
            isDragging = false
            scheduleHideAfterDrop()
        default:
            break
        }
    }

    private func requestPanelPosition(_ screenPoint: NSPoint) {
        pendingScreenPoint = screenPoint

        guard pendingPositionUpdate == nil else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, let screenPoint = self.pendingScreenPoint else {
                return
            }

            self.pendingPositionUpdate = nil
            self.pendingScreenPoint = nil
            self.showOrMovePanel(at: screenPoint)
        }

        pendingPositionUpdate = workItem
        DispatchQueue.main.async(execute: workItem)
    }

    private func scheduleHideAfterDrop() {
        pendingHide?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if case .working = self.hudModel.status {
                return
            }
            self.hidePanel()
        }

        pendingHide = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.35,
            execute: workItem
        )
    }

    private func showOrMovePanel(at screenPoint: NSPoint) {
        let panel = makePanelIfNeeded()
        let origin = NSPoint(
            x: screenPoint.x - panel.frame.width / 2,
            y: screenPoint.y - panel.frame.height / 2
        )
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            panel.setFrameOrigin(origin)
        }

        if !isShowingPanel {
            isShowingPanel = true
            hudModel.status = .idle
            hudModel.fileCount = 0
            panel.orderFrontRegardless()
            panel.alphaValue = 1
        }
    }

    private func hidePanel() {
        guard let panel, isShowingPanel else { return }
        isShowingPanel = false
        panel.alphaValue = 0
        panel.orderOut(nil)
        panel.alphaValue = 1
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel { return panel }

        hudModel.onDrop = { [weak self] format, urls in
            self?.convert(urls: urls, to: format)
        }

        let hostingView = NSHostingView(
            rootView: RadialDonutView(model: hudModel)
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: 360, height: 360)

        let panel = NSPanel(
            contentRect: hostingView.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        hostingView.wantsLayer = true
        hostingView.layer?.isOpaque = false
        hostingView.layer?.drawsAsynchronously = true
        hostingView.layer?.contentsFormat = .RGBA16Float

        self.panel = panel
        return panel
    }

    private func convert(urls: [URL], to format: OutputFormat) {
        guard !urls.isEmpty else {
            hudModel.status = .failed("No readable files were dropped.")
            scheduleHideAfterResult(after: 2.0)
            return
        }
        guard conversionTask == nil else { return }

        let currentConversionID = UUID()
        conversionID = currentConversionID
        conversionTask = Task.detached(priority: .userInitiated) { [converter] in
            var convertedCount = 0
            var failedCount = 0
            var firstError: String?

            for url in urls {
                if Task.isCancelled { return }
                do {
                    _ = try converter.convert(sourceURL: url, to: format)
                    convertedCount += 1
                } catch {
                    failedCount += 1
                    firstError = firstError ?? error.localizedDescription
                }
            }

            let result = (convertedCount, failedCount, firstError)
            await MainActor.run { [weak self] in
                guard let self, self.conversionID == currentConversionID else {
                    return
                }
                self.conversionTask = nil
                if result.0 > 0 {
                    NSSound(named: "Glass")?.play()
                    self.hudModel.status = .done(
                        converted: result.0,
                        failed: result.1,
                        format: format
                    )
                    NSLog(
                        "Converted \(result.0) file(s) to \(format.displayName); "
                            + "\(result.1) failed"
                    )
                    self.scheduleHideAfterResult(after: 1.2)
                } else {
                    NSSound.beep()
                    let message = result.2 ?? "No files were converted."
                    self.hudModel.status = .failed(message)
                    NSLog("Conversion failed: \(message)")
                    self.scheduleHideAfterResult(after: 2.0)
                }
            }
        }
    }

    private func scheduleHideAfterResult(after delay: TimeInterval) {
        pendingHide?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.hidePanel()
        }

        pendingHide = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay,
            execute: workItem
        )
    }
}
