//
//  CreatingPhase.swift
//  TradingChronical
//
//  Created by Paweł Karaś on 28/12/2022.
//

import Foundation
import SwiftUI

enum OandaMode {
    case FXTrade
    case FXPractice
}

func modeToValue(_ mode: OandaMode) -> String {
    switch mode {
    case .FXTrade:
        return "fxt"
    case .FXPractice:
        return "fxp"
    }
}

func valueToMode(_ value: String) -> OandaMode {
    switch value {
    case "fxt":
        return OandaMode.FXTrade
    default:
        return OandaMode.FXPractice
    }
}

func hour(_ amount: Double) -> TimeInterval {
    return 60 * 60 * amount
}

struct CreatingPhase: View {
    @EnvironmentObject var authData: AuthData
    @Binding var state: AppState
    @Binding var candles: [Candle]
    @Binding var error: String?
    @Binding var progress: Double
    @State var from = Date()
    @State var to = Date()
    @State var granularity = Granularity.m1
    @State var instruments: [String] = []
    @State var instrument = "GBP_USD"
    @State var candlePricing = CandlePricingType.bid
    
    func fetchCandles(cb: (Double) -> Void) async {
        let request = Request(authData)
        let hour_count: Double = 8
        let fromDate = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: from)!
        let toDate = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: to)!
        // Get the total amount of time units to calculate
        let interval = toDate.timeIntervalSince(fromDate)
        let hours = interval / hour(hour_count) as Double
        // Currently processed time unit
        var index = 0
        // Variables used to iterate over time
        var currentDate = fromDate
        var nextDate = fromDate + hour(hour_count)
        // Cannot calculate the range of just today
        if self.from == self.to {
            self.error = "Please select a bigger timestamp"
            return
        }
        // Cannot download candles from the future
        if self.to > Date() {
            self.error = "Cannot download candles from the future (You wish... 💸)"
            return
        }
        // Result of this function containing all fetched candles
        var result: [(Int, [Candle])] = []
        while (nextDate < to) {
            let batch = await withTaskGroup(of: Result<(Int, [Candle]), RequestError>?.self) { group -> [(Int, [Candle])] in
                // Create eight parallel workers that fetch the candles
                for _ in 0...8 {
                    if (nextDate >= to) {
                        break
                    }
                    let from = currentDate
                    let to = nextDate
                    let idx = index
                    index += 1
                    group.addTask {
                        do {
                            return try await request
                                .getCandles(from: from, to: to, gran: self.granularity, instrument: self.instrument, pricing: self.candlePricing)
                                .map { (idx, $0.candles) }
                        } catch {
                            return nil
                        }
                    }
                    currentDate = nextDate
                    nextDate += hour(hour_count)
                }
                var result: [(Int, [Candle])] = []
                // Aggregate the results
                for await value in group {
                    if let resultVal = value {
                        switch resultVal {
                        case .success(let candles):
                            result.append(candles)
                        case .failure(let error):
                            self.error = error.value
                        }
                    }
                }
                return result
            }
            cb(Double(index) / hours)
            result += batch
        }
        // Sort the concurrently fetched candles
        self.candles = result
            .sorted(by: { (a, b) in a.0 < b.0 })
            .map { $0.1 }
            .reduce([], +)
    }
    
    var body: some View {
        VStack {
            Text("Specify the configuration").font(.largeTitle).padding()
            HStack {
                Picker("", selection: $granularity) {
                    ForEach(Granularity.allCases) { gran in
                        Text(gran.getName()).tag(gran)
                    }
                }.frame(width: 100)
                if !self.instruments.isEmpty {
                    Picker("", selection: $instrument) {
                        ForEach(instruments, id: \.self) { instr in
                            Text(instr).tag(instr)
                        }
                    }.frame(width: 100)
                } else {
                    ProgressView().onAppear {
                        Task {
                            if let instruments = try await Request(authData).getInstruments() {
                                self.instruments = instruments
                            }
                        }
                    }.padding()
                }
                Picker("", selection: $candlePricing) {
                    ForEach(CandlePricingType.allCases) { pricing in
                        Text(pricing.getName()).tag(pricing)
                    }
                }.frame(width: 100)
            }
            HStack{
                DatePicker(
                    "From",
                    selection: $from,
                    displayedComponents: [.date]
                ).frame(width: 200)
                DatePicker(
                    "To",
                    selection: $to,
                    displayedComponents: [.date]
                ).frame(width: 200)
            }.padding()
            Button(action: {
                storeDataInKeychain("token", data: self.authData.token)
                storeDataInKeychain("mode", data: modeToValue(self.authData.mode))
                self.state = .Fetching
                Task {
                    await self.fetchCandles { value in
                        DispatchQueue.main.async {
                            self.progress = value
                        }
                    }
                    if !self.candles.isEmpty {
                        self.state = .Success
                    } else {
                        self.state = .Error
                    }
                }
            }) { Text("Submit") }
        }.padding().frame(maxHeight: .infinity, alignment: .top)
    }
}
