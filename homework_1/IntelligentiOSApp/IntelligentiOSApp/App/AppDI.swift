//
//  AppDI.swift
//  IntelligentiOSApp
//
//  Created by Верховный Маг on 23.01.2026.
//

import Foundation

final class AppDI {
    static let shared = AppDI()

    private init() {}

    lazy var mobileNetClassifier: ImageClassifierProtocol = {
        try! ImageClassifier(type: .mobileNet)
    }()

    lazy var catsDogsClassifier: ImageClassifierProtocol = {
        try! ImageClassifier(type: .catsDogs)
    }()
    
    lazy var pythonConvertedClassifier: ImageClassifierProtocol = {
        try! ImageClassifier(type: .pythonConverted)
    }()
}
