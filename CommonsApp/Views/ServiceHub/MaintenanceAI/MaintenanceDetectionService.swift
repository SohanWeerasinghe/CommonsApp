//
//  MaintenanceDetectionService.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 29/9/2026.
//

import Foundation
import CoreML
import Vision
import UIKit


struct MaintenanceDetection: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}


enum MaintenanceDetectionError: LocalizedError {
    case invalidImage
    case missingOutput
    case invalidOutputShape

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image could not be processed."

        case .missingOutput:
            return "The AI model did not return the expected outputs."

        case .invalidOutputShape:
            return "The AI model returned an unexpected output shape."
        }
    }
}


final class MaintenanceDetectionService {

    private let model: MLModel
    private let classNames: [String]


    init() throws {

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all

        guard let url = Bundle.main.url(
            forResource: "MaintenanceYOLO",
            withExtension: "mlmodelc"
        ) else {
            throw NSError(
                domain: "MaintenanceAI",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The compiled maintenance model was not found."
                ]
            )
        }

        model = try MLModel(
            contentsOf: url,
            configuration: configuration
        )

        let metadata = model.modelDescription.metadata[
            .creatorDefinedKey
        ] as? [String: String]

        let names = metadata?["classes"] ?? ""

        let parsedNames = Self.parseClassNames(names)

        if parsedNames.count == 21 {
            classNames = parsedNames
        } else {
            classNames = Self.maintenanceClassNames
        }
    }


    func detect(
        image: UIImage,
        confidenceThreshold: Double = 0.25
    ) throws -> [MaintenanceDetection] {

        guard let pixelBuffer = Self.makePixelBuffer(
            from: image,
            width: 640,
            height: 640
        ) else {
            throw MaintenanceDetectionError.invalidImage
        }


        let input = try MLDictionaryFeatureProvider(
            dictionary: [
                "image": MLFeatureValue(pixelBuffer: pixelBuffer),

                "confidenceThreshold": MLFeatureValue(
                    double: confidenceThreshold
                ),

                "iouThreshold": MLFeatureValue(
                    double: 0.7
                )
            ]
        )


        let output = try model.prediction(from: input)


        guard let confidence = output.featureValue(
            for: "confidence"
        )?.multiArrayValue else {
            throw MaintenanceDetectionError.missingOutput
        }


        guard let coordinates = output.featureValue(
            for: "coordinates"
        )?.multiArrayValue else {
            throw MaintenanceDetectionError.missingOutput
        }


        if confidence.shape.count != 2 {
            throw MaintenanceDetectionError.invalidOutputShape
        }

        if coordinates.shape.count != 2 {
            throw MaintenanceDetectionError.invalidOutputShape
        }

        if confidence.shape[0].intValue != coordinates.shape[0].intValue {
            throw MaintenanceDetectionError.invalidOutputShape
        }

        if coordinates.shape[1].intValue != 4 {
            throw MaintenanceDetectionError.invalidOutputShape
        }


        let boxCount = confidence.shape[0].intValue
        let outputClassCount = confidence.shape[1].intValue

        var classCount = outputClassCount

        if classNames.count < outputClassCount {
            classCount = classNames.count
        }


        var results: [MaintenanceDetection] = []


        for boxIndex in 0..<boxCount {

            var bestClass = 0
            var bestScore: Float = 0


            for classIndex in 0..<classCount {

                let score = confidence[
                    [
                        NSNumber(value: boxIndex),
                        NSNumber(value: classIndex)
                    ]
                ].floatValue


                if score > bestScore {
                    bestScore = score
                    bestClass = classIndex
                }
            }


            if bestScore < Float(confidenceThreshold) {
                continue
            }


            let centerX = CGFloat(
                coordinates[
                    [
                        NSNumber(value: boxIndex),
                        NSNumber(value: 0)
                    ]
                ].doubleValue
            )

            let centerY = CGFloat(
                coordinates[
                    [
                        NSNumber(value: boxIndex),
                        NSNumber(value: 1)
                    ]
                ].doubleValue
            )

            let width = CGFloat(
                coordinates[
                    [
                        NSNumber(value: boxIndex),
                        NSNumber(value: 2)
                    ]
                ].doubleValue
            )

            let height = CGFloat(
                coordinates[
                    [
                        NSNumber(value: boxIndex),
                        NSNumber(value: 3)
                    ]
                ].doubleValue
            )


            let x = centerX - width / 2
            let y = centerY - height / 2


            let rectangle = CGRect(
                x: x,
                y: y,
                width: width,
                height: height
            )


            var label = "Unknown"

            if bestClass < classNames.count {
                label = classNames[bestClass]
            }


            let hiddenClasses = [
                "faucet",
                "door",
                "door_not_closing",
                "hinge",
                "door_handle",
                "broken_shower_head"
            ]


            if hiddenClasses.contains(label) {
                continue
            }


            var displayLabel = label


            if label == "leaking_pipe" {
                displayLabel = "Water Leak"
            } else if label == "water_leak" {
                displayLabel = "Water Leak"
            } else if label == "leaking_faucet" {
                displayLabel = "Leaking Faucet"
            } else if label == "pipe_burst" {
                displayLabel = "Pipe Burst"
            } else if label == "clogged_sink" {
                displayLabel = "Clogged Sink"
            } else if label == "toilet_issue" {
                displayLabel = "Toilet Issue"
            } else if label == "water_damage" {
                displayLabel = "Water Damage"
            } else if label == "broken_door" {
                displayLabel = "Broken Door"
            } else if label == "broken_hinge" {
                displayLabel = "Broken Hinge"
            } else if label == "wall_crack" {
                displayLabel = "Wall Crack"
            } else if label == "wall_damage" {
                displayLabel = "Wall Damage"
            } else if label == "floor_crack" {
                displayLabel = "Floor Crack"
            } else if label == "window_crack" {
                displayLabel = "Window Crack"
            } else if label == "broken_window_frame" {
                displayLabel = "Broken Window Frame"
            } else if label == "ceiling_leak" {
                displayLabel = "Ceiling Leak"
            }


            let detection = MaintenanceDetection(
                label: displayLabel,
                confidence: bestScore,
                boundingBox: rectangle
            )

            results.append(detection)
        }


        results.sort {
            firstDetection,
            secondDetection in

            return firstDetection.confidence > secondDetection.confidence
        }


        return results
    }


    private static func makePixelBuffer(
        from image: UIImage,
        width: Int,
        height: Int
    ) -> CVPixelBuffer? {

        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]


        var buffer: CVPixelBuffer?


        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &buffer
        )


        if status != kCVReturnSuccess {
            return nil
        }


        guard let buffer = buffer else {
            return nil
        }


        CVPixelBufferLockBaseAddress(buffer, [])


        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {

            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }


        guard let cgImage = image.cgImage else {

            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }


        let imageRectangle = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height
        )


        context.draw(
            cgImage,
            in: imageRectangle
        )


        CVPixelBufferUnlockBaseAddress(buffer, [])


        return buffer
    }


    private static func parseClassNames(
        _ metadata: String
    ) -> [String] {

        let pattern = #"(\d+):\s*['"]([^'"]+)['"]"#


        guard let regex = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return []
        }


        let range = NSRange(
            metadata.startIndex..<metadata.endIndex,
            in: metadata
        )


        let matches = regex.matches(
            in: metadata,
            range: range
        )


        var labels: [Int: String] = [:]


        for match in matches {

            let indexMatch = match.range(at: 1)
            let nameMatch = match.range(at: 2)


            guard let indexRange = Range(
                indexMatch,
                in: metadata
            ) else {
                continue
            }


            guard let nameRange = Range(
                nameMatch,
                in: metadata
            ) else {
                continue
            }


            let indexText = String(
                metadata[indexRange]
            )


            guard let index = Int(indexText) else {
                continue
            }


            let name = String(
                metadata[nameRange]
            )


            labels[index] = name
        }


        guard let maximumIndex = labels.keys.max() else {
            return []
        }


        var classList: [String] = []


        for index in 0...maximumIndex {

            if let name = labels[index] {
                classList.append(name)
            } else {
                classList.append("Class \(index)")
            }
        }


        return classList
    }


    private static let maintenanceClassNames = [
        "faucet",
        "leaking_faucet",
        "leaking_pipe",
        "pipe_burst",
        "clogged_sink",
        "toilet_issue",
        "water_leak",
        "water_damage",
        "door",
        "broken_door",
        "door_not_closing",
        "hinge",
        "broken_hinge",
        "door_handle",
        "wall_crack",
        "wall_damage",
        "floor_crack",
        "window_crack",
        "broken_window_frame",
        "broken_shower_head",
        "ceiling_leak"
    ]
}

