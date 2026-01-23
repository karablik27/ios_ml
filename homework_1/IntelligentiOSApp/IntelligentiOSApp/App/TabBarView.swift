//
//  TabBarView.swift
//  IntelligentiOSApp
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

struct TabBarView: View {

    private let coreMLComponent: any ClassificationComponentProtocol
    private let createMLComponent: any ClassificationComponentProtocol
    private let pythonMLComponent: any ClassificationComponentProtocol

    init() {
        let di = AppDI.shared

        self.coreMLComponent = ClassificationComponent(
            classifier: di.mobileNetClassifier
        )

        self.createMLComponent = ClassificationComponent(
            classifier: di.catsDogsClassifier
        )

        self.pythonMLComponent = ClassificationComponent(
            classifier: di.pythonConvertedClassifier
        )
    }

    var body: some View {
        TabView {

            coreMLComponent.view.eraseToAnyView()
                .tabItem {
                    Label("Core ML", systemImage: "brain")
                }

            createMLComponent.view.eraseToAnyView()
                .tabItem {
                    Label("Create ML", systemImage: "hammer")
                }

            pythonMLComponent.view.eraseToAnyView()
                .tabItem {
                    Label("Python ML", systemImage: "terminal")
                }
        }
    }
}
