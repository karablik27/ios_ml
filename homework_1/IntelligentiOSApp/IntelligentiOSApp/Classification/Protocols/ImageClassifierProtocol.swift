//
//  ImageClassifierProtocol.swift
//  IntelligentiOSApp
//
//  Created by Верховный Маг on 23.01.2026.
//

import Vision

protocol ImageClassifierProtocol {
    func classify(image: CGImage) throws -> VNClassificationObservation
}
