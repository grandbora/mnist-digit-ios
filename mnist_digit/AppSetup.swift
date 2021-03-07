import SwiftUI

struct AppSetup: View {
    @StateObject private var cameraService = CameraService()
    private var module: MnistModule = {
        if let filePath = Bundle.main.path(forResource: "traced_script_module", ofType: "pt"),
           let module = MnistModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Could not instantiate the module")
        }
    }()
    
    private var prediction: PredictionResult {
        cameraService.imageStream.modelData == nil ? PredictionResult.empty() :
            PredictionService.predict(img: cameraService.imageStream.modelImage!, module: module)
    }
    
    private var predictionFromStaticImage: PredictionResult {
        let optionalImg = UIImage(named: "three")
        
        guard let img = optionalImg else {
            return PredictionResult.empty()
        }
        
        return PredictionService.predict(img: img, module: module)
    }
    
    var body: some View {
        LandingPage(imageStream: cameraService.imageStream, prediction: prediction)
    }
}
