//
//  DemoImage.swift
//  IntelligentiOSApp
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

enum DemoImage: String, CaseIterable, Identifiable {
    case cat
    case dog
    case gunwest

    var id: String { rawValue }
}
