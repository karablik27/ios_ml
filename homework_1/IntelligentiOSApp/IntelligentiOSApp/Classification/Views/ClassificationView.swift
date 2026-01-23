//
//  ClassificationView.swift
//  IntelligentiOSApp
//
//  Created by Верховный Маг on 23.01.2026.
//

import SwiftUI

struct ClassificationView: View {

    @StateObject private var viewModel: ClassificationViewModel
    @State private var selectedImage: DemoImage = .cat

    init(viewModel: @autoclosure @escaping () -> ClassificationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 20) {

            TabView(selection: $selectedImage) {
                ForEach(DemoImage.allCases) { image in
                    Image(image.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .tag(image)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 260)

            Text(viewModel.resultText)
                .font(.headline)
                .multilineTextAlignment(.center)

            Button("Классифицировать") {
                viewModel.classify(imageName: selectedImage.rawValue)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}


