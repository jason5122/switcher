import Cocoa
import ScreenCaptureKit

@objcMembers
class SwiftCaptureView: NSView {
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

class CaptureEngine: NSObject {
    var config: SCStreamConfiguration?
    private var stream: SCStream?
    private var streamOutput: CaptureOutput?
    private var continuation: AsyncStream<IOSurface>.Continuation?
    private let startedSem = DispatchSemaphore(value: 0)

    init(configuration: SCStreamConfiguration) {
        self.config = configuration
    }

    func startCapture(filter: SCContentFilter) -> AsyncStream<IOSurface> {
        AsyncStream<IOSurface> { continuation in
            streamOutput = CaptureOutput()
            streamOutput?.capturedFrameHandler = { continuation.yield($0) }

            do {
                stream = SCStream(
                    filter: filter, configuration: config!, delegate: streamOutput)
                try stream?.addStreamOutput(streamOutput!, type: .screen, sampleHandlerQueue: nil)

                let sem = DispatchSemaphore(value: 0)
                stream?.startCapture(completionHandler: { error in
                    if let error {
                        LogUtil.customLog(.error, "capture-engine", error.localizedDescription)
                    } else {
                        sem.signal()
                    }
                })
                sem.wait()

                startedSem.signal()
            } catch {}
        }
    }

    func stopCapture() {
        startedSem.wait()

        let sem = DispatchSemaphore(value: 0)
        stream?.stopCapture(completionHandler: { error in
            if let error {
                LogUtil.customLog(.error, "capture-engine", error.localizedDescription)
            } else {
                sem.signal()
            }
        })
        sem.wait()

        continuation?.finish()
    }
}

private class CaptureOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    var capturedFrameHandler: ((IOSurface) -> Void)?

    func stream(
        _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard sampleBuffer.isValid else { return }
        if outputType == .screen {
            guard let frame = createFrame(for: sampleBuffer) else { return }
            capturedFrameHandler?(frame)
        }
    }

    private func createFrame(for sampleBuffer: CMSampleBuffer) -> IOSurface? {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil }
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            return nil
        }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        return surface
    }
}
