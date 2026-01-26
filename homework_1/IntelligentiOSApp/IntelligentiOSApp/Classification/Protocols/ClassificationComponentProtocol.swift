//
//  ClassificationComponentProtocol.swift
//  IntelligentiOSApp
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

public protocol ClassificationComponentProtocol {
    associatedtype Body: View

    @MainActor
    var view: Body { get }
}

