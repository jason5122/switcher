import Cocoa
import ScreenCaptureKit

@objcMembers
class CapturePreview: NSView {
    var captureEngine: CaptureEngine?
    var filter: SCContentFilter?

    init(frame: CGRect, configuration: SCStreamConfiguration) {
        super.init(frame: frame)
        self.captureEngine = CaptureEngine(configuration: configuration)

        wantsLayer = true
    }

    func update(filter: SCContentFilter) {
        self.filter = filter
    }

    func startCapture() async {
        for await surface in captureEngine!.startCapture(filter: filter!) {
            self.layer?.contents = surface
        }
    }

    func stopCapture() {
        captureEngine!.stopCapture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
