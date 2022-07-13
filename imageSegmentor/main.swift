//
//  main.swift
//  imageSegmentor
//
//  Created by Kristina Nikkhah on 6/27/22.
//

import Foundation
import CoreImage
import Cocoa
import Vision

enum SegmentationWorkerError: Error {
    case missingFrameImageBuffer
    case missingSegmentationResult
}



print("Getting list of all images in directory")
let fileManager = FileManager.default
let directoryURL = URL(fileURLWithPath: "/Users/studio/Workbench/images")


let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

print("\(fileURLs.count) files found")

for file in fileURLs {
    //    let image = NSImage(contentsOf: file)
    //    print("width: \(image?.size.width) height: \(image?.size.height)")
    let output = segmentImage(imageURL: file)
}

// Performs the blend operation.
private func blend(originalImage: CIImage, mask maskPixelBuffer: CVPixelBuffer) -> CIImage? {
    
    // Create CIImage objects for the video frame and the segmentation mask.
    //        guard let originalImage = CIImage(contentsOf: originalURL) else { return nil } // CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)
    var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
    let tSize = originalImage.extent.size
    guard let backgroundImage = NSImage.from(color: .white, size: CGSize(width: tSize.width/2, height: tSize.height/2))?.toCIImage() else { return nil }
    
    
    // Scale the mask image to fit the bounds of the video frame.
    let scaleX = originalImage.extent.width / maskImage.extent.width
    let scaleY = originalImage.extent.height / maskImage.extent.height
    maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
    
    
    
    // Blend the original, background, and mask images.
    let blendFilter = CIFilter(name: "CIBlendWithMask")
    blendFilter?.setValue(originalImage, forKey: kCIInputImageKey)
    blendFilter?.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
    blendFilter?.setValue(maskImage, forKey: kCIInputMaskImageKey)
    //    let blendFilter = CIFilter
    /*blendFilter.inputImage = originalImage
     blendFilter.backgroundImage = backgroundImage
     blendFilter.maskImage = maskImage*/
    
    // Set the new, blended image as current.
    // currentCIImage = blendFilter.outputImage?.oriented(.left)
    let result = blendFilter?.outputImage
    return result
}

func segmentImage(imageURL: URL) -> NSImage {
    //    let nextSampleBuffer = image
    
    guard let ciOriginalImage = CIImage(contentsOf: imageURL) else { return NSImage() }
    print("CIOriginal Size", ciOriginalImage.extent.size)
    
    
    let d = Date()
    //    let requestHandler = VNImageRequestHandler(cmSampleBuffer: image as! CMSampleBuffer, options: [:])
    // let requestHandler = VNImageRequestHandler(url: imageURL, options: [:])
    let requestHandler = VNImageRequestHandler(ciImage: ciOriginalImage, options: [:])
    
    
    // take in image (call function in paragraph thing above) (already did). then segment the image.
    // then return the resulting image
    let request = VNGeneratePersonSegmentationRequest()
    //request.qualityLevel = personSegmentationQualityLevel
    request.qualityLevel = .accurate
    
    do {
        //        guard let pixelBuffer = nextSampleBuffer.imageBuffer else {
        //            throw SegmentationWorkerError.missingFrameImageBuffer
        //        }
        
        // Performing Person Segmentation
        
        try requestHandler.perform([request])
        
        guard let maskPixelBuffer = request.results?.first?.pixelBuffer else {
            throw SegmentationWorkerError.missingSegmentationResult
        }
        let w = CVPixelBufferGetWidth(maskPixelBuffer)
        let h = CVPixelBufferGetHeight(maskPixelBuffer)
        print("Mask size", w, h)
        
        
        // Composing and rendering composition
        
        /*
         let mask = Helpers.texture(from: maskPixelBuffer, format: .r8Unorm, planeIndex: 0, textureCache: metalTextureCache)
         
         let luma = Helpers.texture(from: pixelBuffer, format: .r8Unorm, planeIndex: 0, textureCache: metalTextureCache)
         let chroma = Helpers.texture(from: pixelBuffer, format: .rg8Unorm, planeIndex: 1, textureCache: metalTextureCache)
         
         framePlaneNode.geometry?.firstMaterial?.transparent.contents = luma
         framePlaneNode.geometry?.firstMaterial?.diffuse.contents = chroma
         framePlaneNode.geometry?.firstMaterial?.specular.contents = backgroundImage
         framePlaneNode.geometry?.firstMaterial?.ambient.contents = mask
         
         let result = sceneRenderer.snapshot(atTime: 0, with: videoSize, antialiasingMode: SCNAntialiasingMode.none)
         */
        
        
        print("Took", Date().timeIntervalSince(d))
        
        _ = blend(originalImage: ciOriginalImage, mask: maskPixelBuffer)
        
        
        // print(maskPixelBuffer)
        // let image = maskPixelBuffer.toNSImage()
        //print(image)
        
    } catch {
        print(#function, error.localizedDescription)
    }
    return NSImage()
    
}

