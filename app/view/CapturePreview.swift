import Cocoa
import ScreenCaptureKit

@objcMembers
class CapturePreview: NSView {
    var selectedWindow: SCWindow?
    private let captureEngine = CaptureEngine()

    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        self.layer?.backgroundColor = NSColor.red.cgColor
    }

    func startCapture() async {
        do {
            let availableContent = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true)
            let windows = filterWindows(availableContent.windows)
            selectedWindow = windows.first

            let title = selectedWindow?.title ?? "no title"
            LogUtil.customLog(.default, "person", "selected window title: %@", title)
        } catch {}

        for await surface in captureEngine.startCapture(window: selectedWindow!) {
            self.layer?.contents = surface
        }
    }

    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        windows
            // Sort the windows by app name.
            .sorted {
                $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName
                    ?? ""
            }
            // Remove windows that don't have an associated .app bundle.
            .filter { $0.owningApplication != nil && $0.owningApplication?.applicationName != "" }
            // Remove this app's window from the list.
            .filter { $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier }
            .filter { $0.owningApplication?.applicationName != "Control Center" }
            .filter { $0.owningApplication?.applicationName != "Dock" }
            // Remove Menu Bar items
            .filter { $0.title != "Item-0" }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
