//
//  PropertyData.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 25.02.2026.
//

import Foundation

struct PropertyData {
    
    let area: Double
    let rooms: Double
    let bathrooms: Double
    let garage: Double
    let distance: Double
    let floor: Double
    let year: Double
    
    init?(
        area: String,
        rooms: String,
        bathrooms: String,
        garage: String,
        distance: String,
        floor: String,
        year: String
    ) {
        guard
            let area = Double(area),
            let rooms = Double(rooms),
            let bathrooms = Double(bathrooms),
            let garage = Double(garage),
            let distance = Double(distance),
            let floor = Double(floor),
            let year = Double(year)
        else { return nil }
        
        self.area = area
        self.rooms = rooms
        self.bathrooms = bathrooms
        self.garage = garage
        self.distance = distance
        self.floor = floor
        self.year = year
    }
}
