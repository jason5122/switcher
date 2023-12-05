import Foundation
import ScreenCaptureKit

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

                let startCompletedSem = DispatchSemaphore(value: 0)
                stream?.startCapture(completionHandler: { error in
                    if let error {
                        LogUtil.customLog(.error, "capture-engine", error.localizedDescription)
                    } else {
                        startCompletedSem.signal()
                    }
                })
                startCompletedSem.wait()

                startedSem.signal()
            } catch {}
        }
    }

    func stopCapture() {
        startedSem.wait()
        Task {
            do {
                try await stream?.stopCapture()
                continuation?.finish()
            } catch {}
        }
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
