//
//  ClassificationView.swift
//  IntelligentiOSApp
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI
import PhotosUI

struct ClassificationView: View {

    @StateObject private var viewModel: ClassificationViewModel

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    init(viewModel: @autoclosure @escaping () -> ClassificationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 20) {

            Group {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                } else {
                    Rectangle()
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 250)
                        .overlay(
                            Text("Выберите фото")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .cornerRadius(12)

            Text(viewModel.resultText)
                .font(.headline)
                .multilineTextAlignment(.center)

            PhotosPicker(
                "Выбрать фото",
                selection: $selectedItem,
                matching: .images
            )

            Button("Классифицировать") {
                viewModel.classify(image: selectedImage)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedImage == nil)
        }
        .padding()
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    viewModel.resultText = "Нажмите «Классифицировать»"
                }
            }
        }
    }
}


