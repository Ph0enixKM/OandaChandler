//
//  Granularity.swift
//  OandaChandler
//
//  Created by Paweł Karaś on 01/01/2023.
//

import Foundation

enum Granularity: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case m1 = "M1"
    case m2 = "M2"
    case m5 = "M5"
    case m10 = "M10"
    case m15 = "M15"
    case m30 = "M30"
    case h1 = "H1"
    case h2 = "H2"
    case h4 = "H4"
    
    func getName() -> String {
        switch self {
        case .m1:
            return "1 Minute"
        case .m2:
            return "2 Minute"
        case .m5:
            return "5 Minute"
        case .m10:
            return "10 Minute"
        case .m15:
            return "15 Minute"
        case .m30:
            return "30 Minute"
        case .h1:
            return "1 Hour"
        case .h2:
            return "2 Hour"
        case .h4:
            return "4 Hour"
        }
    }
    
    func getUrl() -> String {
        return self.rawValue
    }
}


