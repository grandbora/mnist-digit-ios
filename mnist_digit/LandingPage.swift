import SwiftUI

struct LandingPage: View {
    let imageStream: ImageStream
    let prediction: PredictionResult
    
    var body: some View {
        VStack{
            HStack{
                ImageWithTitle(title:"Camera Feed", image: self.imageStream.feedImage)
                VStack{
                    ImageWithTitle(title:"Processed Image", image: self.imageStream.processedImage)
                    ImageWithTitle(title:"Resized", image: self.imageStream.modelImage, resize: false)
                }
            }
            PredictionResultView(result: prediction)
        }
    }
}

struct ImageWithTitle: View {
    let title: String
    let image: UIImage?
    var resize: Bool = true
    
    var body: some View {
        VStack{
            Text(title)
            if let img = image {
                if(resize) {
                    Image(uiImage: img).resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(uiImage: img)
                }
            } else {
                Image(uiImage: UIImage(systemName: "heart.fill")!)
            }
        }
    }}

