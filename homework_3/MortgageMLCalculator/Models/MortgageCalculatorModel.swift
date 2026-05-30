//
//  MortgageCalculatorModel.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 25.02.2026.
//

import Foundation
import CoreML

protocol MortgageCalculatorProtocol {
    func predictPrice(property: PropertyData) -> Double
    func calculateMonthlyPayment(price: Double, terms: MortgageTerms) -> Double
}

final class MortgageCalculatorModel: MortgageCalculatorProtocol {
    
    func predictPrice(property: PropertyData) -> Double {
        do {
            let model = try HousePricePredictor(configuration: .init())
            
            let input = HousePricePredictorInput(
                area: Int64(property.area),
                total_rooms: Int64(property.rooms),
                bathrooms: Int64(property.bathrooms),
                garage_spaces: Int64(property.garage),
                distance_to_center: property.distance,
                floor: Int64(property.floor),
                build_year: Int64(property.year)
            )
            
            let prediction = try model.prediction(input: input)
            return Double(prediction.price)
            
        } catch {
            return fallbackPrice(property: property)
        }
    }
    
    func calculateMonthlyPayment(price: Double, terms: MortgageTerms) -> Double {
        
        let loanAmount = price * (100 - terms.downPayment) / 100
        let monthlyRate = (terms.interestRate / 100) / 12
        let months = terms.loanTerm * 12
        
        guard monthlyRate > 0 else {
            return loanAmount / months
        }
        
        let compound = pow(1 + monthlyRate, months)
        let denominator = compound - 1
        
        guard denominator > 0 else {
            return loanAmount / months
        }
        
        return loanAmount * (monthlyRate * compound / denominator)
    }
    
    private func fallbackPrice(property: PropertyData) -> Double {
        let base = property.area * 60_000
        let bonus = property.rooms * 200_000
        let discount = property.distance * 100_000
        let yearBonus = (property.year - 2000) * 10_000
        
        return max(base + bonus - discount + yearBonus, 1_000_000)
    }
}
