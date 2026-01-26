//
//  ClassificationViewModel.swift
//  IntelligentiOSApp
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI
import Combine
import Vision

@MainActor
final class ClassificationViewModel: ObservableObject {

    @Published var resultText = "Нажмите «Классифицировать»"

    private let classifier: ImageClassifierProtocol

    init(classifier: ImageClassifierProtocol) {
        self.classifier = classifier
    }

    func classify(image: UIImage?) {
        guard
            let image,
            let cgImage = image.cgImage
        else {
            resultText = "Нет изображения"
            return
        }

        do {
            let result = try classifier.classify(image: cgImage)
            let percent = Int(result.confidence * 100)
            resultText = "\(result.identifier) (\(percent)%)"
        } catch {
            resultText = "Ошибка классификации"
        }
    }
}
