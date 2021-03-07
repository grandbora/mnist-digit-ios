import SwiftUI
import AVFoundation

struct ImageStream {
    var feedImage: UIImage? = nil
    var processedImage: UIImage? = nil
    var modelImage: UIImage? = nil
    var modelData: CIImage? = nil
}

class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var imageStream = ImageStream()
    private var cameraController: CameraController? = nil
    
    override init() {
        super.init()
        cameraController = CameraController(cameraDelegate: self)
        cameraController!.start()
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Unable to get image from sample buffer")
            return
        }
        
        let ciImage : CIImage = CIImage(cvPixelBuffer: frame)
        let croppedCiImage = crop(ciImage: ciImage)
        let grayCroppedCiImage = makeGrayScale(ciImage: croppedCiImage)
        let modelData = resizeToModel(ciImage: grayCroppedCiImage)
            
        self.imageStream = ImageStream(
            feedImage: makeUiImage(from: ciImage),
            processedImage: makeUiImage(from: grayCroppedCiImage),
            modelImage: makeUiImage(from: modelData),
            modelData: modelData
        )
    }
    
    private func crop(ciImage: CIImage) -> CIImage {
        let shortEdge: CGFloat = ciImage.extent.width / 5
        let xOffset: CGFloat = (ciImage.extent.width - shortEdge) / 2
        let yOffset: CGFloat = (ciImage.extent.height - shortEdge) / 2
        
        return ciImage.cropped(to: CGRect(x: xOffset, y: yOffset, width: shortEdge, height: shortEdge))
    }
    
    private func makeGrayScale(ciImage: CIImage) -> CIImage {
        let filterName = "CIPhotoEffectNoir" // The grayscale filter
        guard let filter = CIFilter(name: filterName) else {
            print("Failed to create grayscale filter")
            return ciImage
        }
        filter.setValue(ciImage, forKey: "inputImage")
        guard let grayImage = filter.outputImage  else {
            print("Filter failed to process the image")
            return ciImage
        }

        return grayImage
    }
    
    private func resizeToModel(ciImage: CIImage) -> CIImage {
        let filterName = "CILanczosScaleTransform" // The resize filter
        guard let filter = CIFilter(name: filterName) else {
            print("Failed to create grayscale filter")
            return ciImage
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1, forKey: kCIInputAspectRatioKey)
        let scale = 28 / ciImage.extent.width
        filter.setValue(scale, forKey: kCIInputScaleKey)
        
        guard let img = filter.outputImage  else {
            print("Filter failed to process the image")
            return ciImage
        }

        return img
    }
    
    private func makeUiImage(from ciImage: CIImage) -> UIImage? {
        let context:CIContext = CIContext.init(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Unable to create cgImage from ciImage")
            return nil
        }
        
        return makeUiImage(from: cgImage)
    }
    
    private func makeUiImage(from cgImage: CGImage) -> UIImage? {
        return UIImage.init(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}

class CameraController {
    private var captureSession: AVCaptureSession

    //    Asking for permission should go somewhere here...
    
    init(cameraDelegate: CameraService) {
        let session = AVCaptureSession()
        session.beginConfiguration()

        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard videoDevice != nil,
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
              session.canAddInput(videoDeviceInput) else {
            fatalError("One of the requirements were not met")
        }
        session.addInput(videoDeviceInput)
    
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings =
            [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoOutput.setSampleBufferDelegate(cameraDelegate, queue: DispatchQueue.main) // has to be the main queue to update the view
        session.addOutput(videoOutput)
        
        session.commitConfiguration()
        self.captureSession = session
    }
    
    func start() {
        self.captureSession.startRunning()
    }
}
