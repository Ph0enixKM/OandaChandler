//
//  Granularity.swift
//  OandaChandler
//
//  Created by Paweł Karaś on 01/01/2023.
//

import Foundation

enum Granularity: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case s5 = "S5"
    case s10 = "S10"
    case s15 = "S15"
    case s30 = "S30"
    case m1 = "M1"
    case m2 = "M2"
    case m5 = "M5"
    case m10 = "M10"
    case m15 = "M15"
    case m30 = "M30"
    case h1 = "H1"
    case h2 = "H2"
    case h4 = "H4"
    case h6 = "H6"
    case h8 = "H8"
    case h12 = "H12"
    case d = "D"
    case w = "W"
    
    func getName() -> String {
        switch self {
        case .s5:
            return "5 Second"
        case .s10:
            return "10 Second"
        case .s15:
            return "15 Second"
        case .s30:
            return "30 Second"
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
        case .h6:
            return "6 Hour"
        case .h8:
            return "8 Hour"
        case .h12:
            return "12 Hour"
        case .d:
            return "Day"
        case .w:
            return "Week"
        }
    }
    
    func getTimeOffset() -> TimeInterval {
        switch self {
        case .s5:
            return 0.5
        case .s10:
            return 1
        case .s15:
            return 2
        case .s30:
            return 4
        case .m1:
            return 8
        case .m2:
            return 16
        default:
            return 24
        }
    }
    
    func getUrl() -> String {
        return self.rawValue
    }
}


