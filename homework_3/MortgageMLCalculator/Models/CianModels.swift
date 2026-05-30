//
//  CianModels.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 27.02.2026.
//

import Foundation

struct CianOffersResponse: Decodable {
    let offers: [CianOffer]
}

struct CianOffer: Decodable {
    let id: String
    let price: Double
    let area: Double
    let rooms: Double
    let floor: Double
    let buildYear: Double
    let address: String
    let district: String
    let metro: String
    let latitude: Double
    let longitude: Double
}
