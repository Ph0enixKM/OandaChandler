import SwiftUI
import Combine
import Foundation
import Dispatch

struct CandleData: Decodable {
  let candles: [Candle]
}

struct Mid: Decodable {
  let o: String
  let h: String
  let l: String
  let c: String
}

struct Candle: Decodable {
    let complete: Bool
    let volume: Int
    let time: String
    let mid: Mid
}

extension Date {
    static func ISOStringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter.string(from: date).appending("Z")
    }
    
    static func dateFromISOString(string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        return dateFormatter.date(from: string)
    }
}

class Candles {
    var candles: [Candle]? = nil
    var error: String? = nil
    var granularity = ""
    var instrument = ""
    var api_key = ""
    var mode = OandaMode.FXTrader
    
    func getRequest(from: Date, to: Date) -> URLRequest {
        let fromString = Date.ISOStringFromDate(date: from)
        let toString = Date.ISOStringFromDate(date: to)
        var mode = "";
        switch self.mode {
        case .FXTrader:
            mode = "fxtrade"
        case .FXPractice:
            mode = "fxpractice"
        }
        let uri = [
            "https://api-\(mode).oanda.com/v3/instruments/\(self.instrument)/candles?",
            "granularity=\(self.granularity)&",
            "from=\(fromString)&",
            "to=\(toString)"
        ].joined(separator: "")
        let url = URL(string: uri)!
        var req = URLRequest(url: url)
        req.addValue("Bearer \(api_key)", forHTTPHeaderField: "Authorization")
        return req
    }
    
    func hour() -> TimeInterval {
        return 60 * 60
    }

    // TODO: Move granularity and instrument to it's own UI Elements
    func fetchCandles(from: Date, to: Date, granularity: String, instrument: String, api_key: String, mode: OandaMode, cb: (Double) -> Void) async -> Bool {
        let fromDate = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: from)!
        let toDate = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: to)!
        self.granularity = granularity
        self.instrument = instrument
        self.api_key = api_key
        self.mode = mode
        var currentDate = fromDate
        var nextDate = fromDate + self.hour()
        var index = 0
        let interval = toDate.timeIntervalSince(fromDate)
        let hours = interval / 3600
        var result: [(Int, [Candle])] = []
        while (nextDate <= to) {
            let batch = await withTaskGroup(of: (Int, [Candle])?.self) { group -> [(Int, [Candle])] in
                for _ in 0...25 {
                    if (currentDate >= to) {
                        break
                    }
                    let request = self.getRequest(from: currentDate, to: nextDate)
                    let idx = index
                    index += 1
                    group.addTask {
                        do {
                            let (data, _) = try await URLSession.shared.data(for: request)
                            let decoded = String(decoding: data, as: UTF8.self)
                            // TODO: Do this in a reasonable way
                            if decoded.starts(with: "{\"errorMessage") {
                                self.error = decoded
                            }
//                            print(String(decoding: data, as: UTF8.self))
                            let candleData = try JSONDecoder().decode(CandleData.self, from: data)
                            return (idx, candleData.candles)
                        } catch {
                            return nil
                        }
                    }
                    currentDate = nextDate
                    nextDate += self.hour()
                }
                var result: [(Int, [Candle])] = []
                for await value in group {
                    if let candles = value {
                        result.append(candles)
                    }
                }
                return result
            }
            cb(Double(index) / hours)
            result += batch
        }
//        print(result.sorted(by: { (a, b) in a.0 < b.0 }).map { ($0.0, $0.1.first?.time, $0.1.last?.time, $0.1.count) })
//        print(result.map { $0.1.map { $0.time } })
//        print(result.map { $0.count })
//        print(result)
        self.candles = result
            .sorted(by: { (a, b) in a.0 < b.0 })
            .map { $0.1 }
            .reduce([], +)
        
        print(self.candles?.first)
        return self.candles?.isEmpty == false
    }
    
    func formatDateString(_ dateString: String) -> String {
        var res = dateString.replacingOccurrences(of: "-", with: ".");
        res = dateString.replacingOccurrences(of: ":", with: ".");
        res = dateString.replacingOccurrences(of: "T", with: ",");
        return String(res[..<String.Index(utf16Offset: 16, in: res)])
    }
    
    func generateCSV(_ url: URL, callback: (Double) -> Void) throws {
        // Reset the contents of the target file
//        try "".data(using: .utf8)!.write(to: url);
//        let fileHandle = try FileHandle(forWritingTo: url)
        var row = ""
        for (index, candle) in self.candles!.enumerated() {
            row += [
                self.formatDateString(candle.time),
                candle.mid.o,
                candle.mid.h,
                candle.mid.l,
                candle.mid.c,
                String(candle.volume)
            ].joined(separator: ",") + "\n"
            if index % 100 == 0 {
                callback(Double(index) / Double(self.candles!.count))
            }
        }
        try row.data(using: .utf8)!.write(to: url)
    }

}

