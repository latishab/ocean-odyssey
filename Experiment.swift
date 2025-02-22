//
//  Experiment.swift
//  Ocean Odyssey
//
//  Created by Latisha on 2/17/25.
//

struct Experiment {
    let title: String
    let description: String
    let interaction: Interaction
    var isCompleted: Bool = false
    
    enum Interaction {
        case colorChangeDemo(name: String, range: ClosedRange<Float>)
        case pressureDemo(name: String, range: ClosedRange<Float>)
        case pressureCalculation(name: String, range: ClosedRange<Float>)
    }
}

