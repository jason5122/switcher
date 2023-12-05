import Foundation
import ScreenCaptureKit

class CaptureEngine: NSObject {
    private var stream: SCStream?
    private var streamOutput: CaptureOutput?
    private var continuation: AsyncStream<IOSurface>.Continuation?

    func startCapture(window: SCWindow) -> AsyncStream<IOSurface> {
        let streamConfig = SCStreamConfiguration()
        streamConfig.width = Int(window.frame.width) * 2
        streamConfig.height = Int(window.frame.height) * 2
        streamConfig.queueDepth = 8
        streamConfig.showsCursor = false
        streamConfig.colorSpaceName = CGColorSpace.sRGB

        let filter = SCContentFilter(desktopIndependentWindow: window)

        return AsyncStream<IOSurface> { continuation in
            streamOutput = CaptureOutput()
            streamOutput?.capturedFrameHandler = { continuation.yield($0) }

            do {
                stream = SCStream(
                    filter: filter, configuration: streamConfig, delegate: streamOutput)
                try stream?.addStreamOutput(streamOutput!, type: .screen, sampleHandlerQueue: nil)
                stream?.startCapture()
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
