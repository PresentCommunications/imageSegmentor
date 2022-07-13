//
//  extensions.swift
//  imageSegmentor
//
//  Created by Kristina Nikkhah on 7/12/22.
//

import Cocoa

extension CVPixelBuffer {
    // CVPixelBuffer to NSImage for display
        func toNSImage() -> NSImage {
            return toNSImage(context: CIContext(options: nil))
        }

        func toNSImage ( context: CIContext ) -> NSImage {
            let pixelBuffer = self
            let ciImage = CIImage(cvImageBuffer: pixelBuffer)
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: width, height: height))!
            let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: width, height: height))
            return nsImage
        }
}
extension NSImage {
    
    static func from ( color: NSColor, size: CGSize ) -> NSImage? {
        let img = NSImage(size: size)
        img.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        img.unlockFocus()
        return img
    }

    func toCGImage() -> CGImage? {
        var rect = NSRect(origin: CGPoint(x: 0, y: 0), size: self.size)
        return self.cgImage(forProposedRect: &rect, context: NSGraphicsContext.current, hints: nil)
    }
    
    func toCIImage() -> CIImage? {
        if let cgImage = toCGImage() {
            return CIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func toCVPixelBuffer() -> CVPixelBuffer? {
            let image = self
            let w = Int(image.size.width)
            let h = Int(image.size.height)
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            var pixelBuffer : CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
            guard (status == kCVReturnSuccess) else {
                return nil
            }

            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: w, height: h, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)

    //        context?.translateBy(x: 0, y: image.size.height)    // float
    //        context?.scaleBy(x: 1.0, y: -1.0)

            let graphicsContext = NSGraphicsContext(cgContext: context!, flipped: false)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = graphicsContext
            draw(in: CGRect(x: 0, y: 0, width: w, height: h), from: .zero, operation: .sourceIn, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()

            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

            return pixelBuffer
        }
}
