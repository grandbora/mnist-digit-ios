import Foundation
import SwiftUI

struct PredictionResult {
    let inputImage: CGImage?
    let topPred: Int
    let topPredConfidence: Float32
    let secondPred: Int
    let secondPredConfidence: Float32
    let thirdPred: Int
    let thirdPredConfidence: Float32;
    
    static func empty() -> PredictionResult {
        PredictionResult(
            inputImage: nil,
            topPred: -1, topPredConfidence: 0,
            secondPred: -1, secondPredConfidence: 0,
            thirdPred: -1, thirdPredConfidence: 0
        )
    }
}

struct PredictionService {
    static func predict(img: UIImage, module: MnistModule) -> PredictionResult {
        
        guard let cgImage = self.makeCgImage(from: img) else {
            print("Failed to get cgImage")
            return PredictionResult.empty()
        }
        
        let rawBytes: [UInt8] = getRawBytes(from: cgImage)
        let formattedPixels: [UInt8] = reorientImage(from: rawBytes)
        var normalizedPixels: [Float32] = normalizeData(data: formattedPixels)
        
        printAsciiImage(normalizedPixels)
        return runInference(normalizedPixels: &normalizedPixels, module: module)
    }
    
    private static func runInference(normalizedPixels: inout [Float32], module: MnistModule) -> PredictionResult {
        
        let outputsOpt: [NSNumber]? = normalizedPixels.withUnsafeMutableBytes { ptr in
            guard let baseAddress = ptr.baseAddress else {
                print("Could not get ptr.baseAddress")
                return nil
            }
            return module.predict(image: UnsafeMutableRawPointer(baseAddress))
        }
        
        guard let outputs = outputsOpt else {
            print("No outputs from the model")
            return PredictionResult.empty()
        }
        
        let sortedOutputs = outputs.enumerated().sorted(by: { (a, b) in
            a.element.floatValue > b.element.floatValue
        })
        
        let inputImage = createInputImage(input: normalizedPixels)
        
        return PredictionResult(
            inputImage: inputImage,
            topPred: sortedOutputs[0].offset, topPredConfidence: sortedOutputs[0].element.floatValue,
            secondPred: sortedOutputs[1].offset, secondPredConfidence: sortedOutputs[1].element.floatValue,
            thirdPred: sortedOutputs[2].offset, thirdPredConfidence: sortedOutputs[2].element.floatValue
        )
    }
    
    private static func getRawBytes(from cgImage: CGImage) -> [UInt8] {
        var rawBytes: [UInt8] = [UInt8](repeating: 0, count: 28 * 28) // 1 bytes per pixel;
        rawBytes.withUnsafeMutableBytes { ptr in
            let contextOpt: CGContext? = CGContext(data: ptr.baseAddress,
                                                   width: 28,
                                                   height: 28,
                                                   bitsPerComponent: 8,
                                                   bytesPerRow: 28, // 28 pixels, 1 byte per pix
                                                   space: CGColorSpaceCreateDeviceGray(),
                                                   bitmapInfo: CGImageAlphaInfo.none.rawValue)
            guard let context = contextOpt else {
                print("Failed to create CGContext")
                return
            }
            
            let rect = CGRect(x: 0, y: 0, width: 28, height: 28)
            context.draw(cgImage, in: rect)
        }
        
        return rawBytes
    }
    
    private static func reorientImage(from rawBytes: [UInt8]) -> [UInt8] {
        // Base 28*28 matrix
        var resultBuffer = [UInt8](repeating: 0, count: 28 * 28)
        
        // Rotates the image
        for row in 0 ..< 28 {
            for col in 0 ..< 28 {
                // decoding pixel location
                // raw data is rotated to right
                // hence each column becomes the row
                let pixIndex = row * 28 + col
                
                // last val of the col is the first val of the row
                let newRow = col
                let newCol = 27 - row
                
                resultBuffer[newRow * 28 + newCol] = rawBytes[pixIndex]
            }
        }
        return resultBuffer
    }
    
    private static func normalizeData(data: [UInt8]) -> [Float32] {
        var normalizedBuffer: [Float32] = [Float32](repeating: 0, count: 28 * 28)
        let mean: Float32 = 0.1307 // mean pixel value
        let std: Float32 = 0.3081 // standard deviation
        
        for i in 0 ..< 28 * 28 {
            let pixVal = data[i]
            let normalizedVal = (Float32(pixVal) / 255 - mean) / std
            normalizedBuffer[i] = normalizedVal
        }
        return normalizedBuffer
    }
    
    private static func makeCgImage(from uiImage: UIImage) -> CGImage? {
        guard let ciImage = CIImage(image: uiImage) else {
            print("Failed to get ci image")
            return nil
        }
        let context:CIContext = CIContext.init(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    private static func createInputImage(input : [Float32]) -> CGImage? {
        var rawBytes: [UInt8] = [UInt8](repeating: 0, count: 28 * 28) // 1 byte per pixel
        
        // Update intensity values
        for i in 0 ..< 28 * 28 {
            let pixelVal = mapModelValueToPixelValue(input: input[i])
            rawBytes[i] = UInt8(bitPattern: pixelVal)
        }
        
        return rawBytes.withUnsafeMutableBytes { ptr in
            let contextOpt: CGContext? = CGContext(data: ptr.baseAddress,
                                                   width: 28,
                                                   height: 28,
                                                   bitsPerComponent: 8,
                                                   bytesPerRow: 28, // 28 pixels * 1 bytes per pix
                                                   space: CGColorSpaceCreateDeviceGray(),
                                                   bitmapInfo: CGImageAlphaInfo.none.rawValue)
            guard let context = contextOpt else {
                print("Failed to create CGContext")
                return nil
            }
            
            return context.makeImage()
        }
    }
    
    private static func mapModelValueToPixelValue(input: Float32) -> Int8 {
        if (input > 3) {
            return -127
        }
        
        if (input > 2) {
            return -75
        }
        
        if (input > 1) {
            return -25
        }
        
        if (input > 0) {
            return 0
        }
        
        if (input > -1) {
            return 25;
        }
        
        if (input > -2) {
            return 75;
        }
        
        return 127
    }
    
    private static func printAsciiImage(_ imgData: [Float32]) {
        var formattedPixels = [[String]](repeating: [String](repeating: "", count: 28), count: 28)
        
        // Print raw pixel forms
        print("!!!ASCII ART!!!")
        for y in 0 ..< 28 {
            for x in 0 ..< 28 {
                let pixIndex = y * 28 + x
                let pixVal = imgData[pixIndex]
                
                // String(format: "%04d:%03d", rPixIndex, fRPix) for index
                // let formatted = String(format: "%.3f", pixVal)
                // let formatted = pixVal > 0 ? String(format: "+%.1f", pixVal) : String(format: "%.1f", pixVal)
                let formatted = pixVal > 0 ? "*" : "."
                
                formattedPixels[y][x] = formatted
            }
        }
        
        
        for y in 0 ..< 28 {
            let joined = formattedPixels[y].joined(separator: " ")
            print(joined)
        }
    }
}
