import SwiftUI
import Combine
import Foundation
import Dispatch

struct CandleData: Decodable {
  let candles: [Candle]
}

struct CandlePricing: Decodable {
  let o: String
  let h: String
  let l: String
  let c: String
}

struct Candle: Decodable {
    let complete: Bool
    let volume: Int
    let time: String
    let mid: CandlePricing?
    let bid: CandlePricing?
    let ask: CandlePricing?
}

enum CandlePricingType: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case mid
    case bid
    case ask
    
    func getName() -> String {
        switch self {
        case .mid:
            return "Mid"
        case .bid:
            return "Bid"
        case .ask:
            return "Ask"
        }
    }
    
    func getUrl() -> String {
        switch self {
        case .mid:
            return "M"
        case .bid:
            return "B"
        case .ask:
            return "A"
        }
    }
}
