//
//  Request.swift
//  OandaChandler
//
//  Created by Paweł Karaś on 01/01/2023.
//

import Foundation
import SwiftUI

struct RequestError: Error {
    var value: String
}

class Request: ObservableObject {
    var authData: AuthData
    
    init(_ authData: AuthData) {
        self.authData = authData
    }
    
    private func request(_ url: [String], query rawQuery: [String:String] = [:]) async throws -> (Data, URLResponse) {
        let query = rawQuery.map { (key, value) in "\(key)=\(value)" }
        var uri = (["https://api-\(authData.modeToUrl()).oanda.com/v3/"] + url).joined(separator: "/")
        if !query.isEmpty { uri += "?\(query.joined(separator: "&"))" }
        let url = URL(string: uri)!
        var req = URLRequest(url: url)
        req.addValue("Bearer \(authData.token)", forHTTPHeaderField: "Authorization")
        print(uri)
        return try await URLSession.shared.data(for: req)
    }
    
    func getAccount() async throws -> String? {
        let (data, _) = try await self.request(["accounts"])
        if let data = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
           let array = data["accounts"] as? [[String: Any]],
           let id = array[0]["id"] as? String {
            return id
        }
        return nil
    }
    
    func getInstruments() async throws -> [String]? {
        guard let account_id = authData.accountId else {
            return nil
        }
        var result: [String] = []
        let (data, _) = try await self.request(["accounts", account_id, "instruments"])
        if let data = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
           let instruments = data["instruments"] as? [[String: Any]] {
            for instrument in instruments {
                if let name = instrument["name"] as? String {
                    result.append(name)
                }
            }
        }
        return result.sorted()
    }
    
    func getCandles(from: Date, to: Date, gran: Granularity, instrument: String, pricing: CandlePricingType) async throws -> Result<CandleData, RequestError> {
        let fromString = Date.ISOStringFromDate(date: from)
        let toString = Date.ISOStringFromDate(date: to)
        let (data, _) = try await self.request(["instruments", instrument, "candles"], query: [
            "granularity": gran.getUrl(),
            "from": fromString,
            "to": toString,
            "price": pricing.getUrl()
        ])
        do {
            return .success(try JSONDecoder().decode(CandleData.self, from: data))
        } catch {
            return .failure(RequestError(value: String(decoding: data, as: UTF8.self)))
        }
    }
}
