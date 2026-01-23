//
//  ImageClassifier.swift
//  IntelligentiOSApp
//
//  Created by Верховный Маг on 23.01.2026.
//

import Vision
import CoreML
import UIKit

final class ImageClassifier: ImageClassifierProtocol {

    private let vnModel: VNCoreMLModel
    

    init(type: ClassifierType) throws {
        let config = MLModelConfiguration()

        switch type {
        case .mobileNet:
            let model = try MobileNetV2(configuration: config).model
            vnModel = try VNCoreMLModel(for: model)

        case .catsDogs:
            let model = try CatsDogsClassifier(configuration: config).model
            vnModel = try VNCoreMLModel(for: model)
        case .pythonConverted:
            let model = try PythonConvertModel(configuration: config).model
            vnModel = try VNCoreMLModel(for: model)
        }
    }

    func classify(image: CGImage) throws -> VNClassificationObservation {
        let request = VNCoreMLRequest(model: vnModel)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])

        guard
            let results = request.results as? [VNClassificationObservation],
            let best = results.first
        else {
            throw NSError(domain: "Classifier", code: -1)
        }

        return best
    }
    
    private func softmax(_ values: [Float]) -> [Float] {
        let maxVal = values.max() ?? 0
        let expValues = values.map { exp($0 - maxVal) }
        let sum = expValues.reduce(0, +)
        return expValues.map { $0 / sum }
    }
}
