import Cocoa
import ScreenCaptureKit

@objcMembers
class CapturePreview: NSView {
    var filter: SCContentFilter?
    var config: SCStreamConfiguration?
    private let captureEngine = CaptureEngine()

    init(frame: CGRect, filter: SCContentFilter, configuration: SCStreamConfiguration) {
        super.init(frame: frame)
        self.filter = filter
        self.config = configuration

        wantsLayer = true
    }

    func startCapture() {
        Task {
            for await surface in captureEngine.startCapture(filter: filter!, configuration: config!)
            {
                self.layer?.contents = surface
            }
        }
    }

    func stopCapture() {
        captureEngine.stopCapture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
