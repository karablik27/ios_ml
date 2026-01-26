//
//  ClassificationComponent.swift
//  IntelligentiOSApp
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

struct ClassificationComponent: ClassificationComponentProtocol {

    let classifier: ImageClassifierProtocol

    init(classifier: ImageClassifierProtocol) {
        self.classifier = classifier
    }

    @MainActor
    var view: some View {
        ClassificationView(viewModel: self.makeViewModel())
    }
}


extension ClassificationComponent {
    func makeViewModel() -> ClassificationViewModel {
        return ClassificationViewModel(classifier: classifier)
    }
}
