import Cocoa
import ScreenCaptureKit

@objcMembers
class SwiftCaptureView: NSView {
    private var captureOutput: CaptureOutput?
    var stream: SCStream?
    let startedSem = DispatchSemaphore(value: 0)
    var filter: SCContentFilter?
    var config: SCStreamConfiguration?
    var continuation: AsyncStream<IOSurface>.Continuation?

    init(frame: CGRect, configuration: SCStreamConfiguration) {
        super.init(frame: frame)
        self.config = configuration

        wantsLayer = true
    }

    func update(filter: SCContentFilter) {
        self.filter = filter
    }

    func startCapture() {
        let asyncStream = AsyncStream<IOSurface> { continuation in
            captureOutput = CaptureOutput()
            captureOutput?.capturedFrameHandler = { continuation.yield($0) }

            do {
                stream = SCStream(filter: filter!, configuration: config!, delegate: nil)
                try stream?.addStreamOutput(captureOutput!, type: .screen, sampleHandlerQueue: nil)

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

        Task {
            for await surface in asyncStream {
                self.layer?.contents = surface
            }
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class CaptureOutput: NSObject, SCStreamOutput {
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
        guard let imageBuffer = sampleBuffer.imageBuffer else { return nil }
        guard let surfaceRef = CVPixelBufferGetIOSurface(imageBuffer)?.takeUnretainedValue() else {
            return nil
        }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        return surface
    }
}
