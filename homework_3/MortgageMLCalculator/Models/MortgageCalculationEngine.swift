//
//  MortgageCalculationEngine.swift
//  MortgageMLCalculator
//
//  Created by Stepan Karabelnikov on 29.05.2026.
//

import CoreML
import Foundation

enum MortgageCalculationEngine {
    nonisolated static func validate(input: MortgageInput, terms: MortgageTerms) -> ValidationResult {
        if input.area < 10 || input.area > 1_000 {
            return ValidationResult(isValid: false, message: "Площадь должна быть от 10 до 1000 м²")
        }

        if input.rooms < 1 || input.rooms > 12 {
            return ValidationResult(isValid: false, message: "Количество комнат должно быть от 1 до 12")
        }

        if input.bathrooms < 1 || input.bathrooms > 8 {
            return ValidationResult(isValid: false, message: "Количество санузлов должно быть от 1 до 8")
        }

        if input.garageSpaces < 0 || input.garageSpaces > 5 {
            return ValidationResult(isValid: false, message: "Парковочных мест должно быть от 0 до 5")
        }

        if input.distanceToCenter < 0 || input.distanceToCenter > 80 {
            return ValidationResult(isValid: false, message: "Расстояние до центра должно быть от 0 до 80 км")
        }

        if input.floor < 1 || input.floor > 100 {
            return ValidationResult(isValid: false, message: "Этаж должен быть от 1 до 100")
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        if input.buildYear < 1900 || input.buildYear > currentYear + 5 {
            return ValidationResult(isValid: false, message: "Год постройки должен быть между 1900 и \(currentYear + 5)")
        }

        if input.balcony < 0 || input.balcony > 5 {
            return ValidationResult(isValid: false, message: "Количество балконов должно быть от 0 до 5")
        }

        if input.renovationLevel < 0 || input.renovationLevel > 4 {
            return ValidationResult(isValid: false, message: "Уровень ремонта должен быть от 0 до 4")
        }

        if input.ceilingHeight < 2.2 || input.ceilingHeight > 5.0 {
            return ValidationResult(isValid: false, message: "Высота потолков должна быть от 2.2 до 5.0 м")
        }

        if input.districtRating < 1 || input.districtRating > 10 {
            return ValidationResult(isValid: false, message: "Рейтинг района должен быть от 1 до 10")
        }

        if terms.downPayment < 10 || terms.downPayment > 90 {
            return ValidationResult(isValid: false, message: "Первоначальный взнос должен быть от 10% до 90%")
        }

        if terms.loanTerm < 1 || terms.loanTerm > 30 {
            return ValidationResult(isValid: false, message: "Срок кредита должен быть от 1 до 30 лет")
        }

        if terms.interestRate < 0.1 || terms.interestRate > 30 {
            return ValidationResult(isValid: false, message: "Ставка должна быть от 0.1% до 30%")
        }

        return ValidationResult(isValid: true, message: nil)
    }

    nonisolated static func calculate(input: MortgageInput, terms: MortgageTerms) -> MortgageCalculation {
        let price = predictPrice(input: input)
        let monthlyPayment = calculateMonthlyPayment(price: price, terms: terms)
        let creditAmount = price * (100 - terms.downPayment) / 100
        let totalPayment = monthlyPayment * terms.loanTerm * 12

        return MortgageCalculation(
            price: price,
            monthlyPayment: monthlyPayment,
            creditAmount: creditAmount,
            totalPayment: totalPayment,
            overpayment: totalPayment - creditAmount
        )
    }

    nonisolated static func predictPrice(input: MortgageInput) -> Double {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all

            let model = try HousePricePredictorExtended(configuration: config)
            let prediction = try model.prediction(
                area: Int64(input.area),
                total_rooms: Int64(input.rooms),
                bathrooms: Int64(input.bathrooms),
                garage_spaces: Int64(input.garageSpaces),
                distance_to_center: input.distanceToCenter,
                floor: Int64(input.floor),
                build_year: Int64(input.buildYear),
                balcony: Int64(input.balcony),
                renovation_level: Int64(input.renovationLevel),
                has_elevator: input.hasElevator ? 1 : 0,
                ceiling_height: input.ceilingHeight,
                district_rating: Int64(input.districtRating)
            )

            return max(prediction.price, 1_000_000)
        } catch {
            return fallbackPrice(input: input)
        }
    }

    nonisolated static func fallbackPrice(input: MortgageInput) -> Double {
        let base = input.area * 90_000
        let roomsBonus = Double(input.rooms) * 300_000
        let bathroomsBonus = Double(input.bathrooms) * 180_000
        let garageBonus = Double(input.garageSpaces) * 250_000
        let balconyBonus = Double(input.balcony) * 120_000
        let renovationBonus = Double(input.renovationLevel) * 400_000
        let elevatorBonus = input.hasElevator ? 350_000.0 : 0
        let ceilingBonus = max(input.ceilingHeight - 2.5, 0) * 800_000
        let districtBonus = Double(input.districtRating) * 250_000
        let distanceDiscount = input.distanceToCenter * 180_000
        let yearBonus = Double(input.buildYear - 2000) * 45_000

        let price = base
            + roomsBonus
            + bathroomsBonus
            + garageBonus
            + balconyBonus
            + renovationBonus
            + elevatorBonus
            + ceilingBonus
            + districtBonus
            + yearBonus
            - distanceDiscount

        return max(price, 1_000_000)
    }

    nonisolated static func calculateMonthlyPayment(price: Double, terms: MortgageTerms) -> Double {
        let loanAmount = price * (100 - terms.downPayment) / 100
        let months = max(terms.loanTerm * 12, 1)
        let monthlyRate = (terms.interestRate / 100) / 12

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
}
