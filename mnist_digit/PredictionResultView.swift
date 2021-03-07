import SwiftUI

struct PredictionResultView: View {
    let result: PredictionResult
    
    var body: some View {
        VStack{
            Text("Model Input")
            if let img = result.inputImage {
                Image(uiImage: UIImage(cgImage: img)).resizable().frame(width: 200, height: 200)
            } else {
                Image(uiImage: UIImage(systemName: "heart.fill")!).resizable().aspectRatio(contentMode: .fit)
            }
            
            PredictionResultRow(positionName: "First", pred: result.topPred, confidence: result.topPredConfidence)
            PredictionResultRow(positionName: "Second", pred: result.secondPred, confidence: result.secondPredConfidence)
            PredictionResultRow(positionName: "Third", pred: result.thirdPred, confidence: result.thirdPredConfidence)
        }
    }
}

struct PredictionResultRow: View {
    let positionName: String
    let pred: Int
    let confidence: Float32
    
    var body: some View {
        HStack{
            Text("\(positionName):").frame(width: 70, alignment: Alignment.leading)
            Text(String(pred)).frame(width: 30, alignment: Alignment.leading)
            Text("Conf:").frame(width: 50, alignment: Alignment.leading)
            Text(formatConfidence(confidence)).frame(width: 100, alignment: Alignment.leading)
        }.background(calculateClor(confidence))
    }
    
    private func formatConfidence(_ conf: Float32) -> String {
        String(format: "%.4f", conf)
    }
    
    private func calculateClor(_ conf: Float32) -> Color {
        let green : Double = (Double) (1 - min(conf * conf / 10, 1)) // 10 is an arbitrary denominator
        return Color(red: 1 - green, green: green, blue: 0.5)
    }
}
