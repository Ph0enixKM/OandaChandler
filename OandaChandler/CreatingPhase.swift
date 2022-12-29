//
//  CreatingPhase.swift
//  TradingChronical
//
//  Created by Paweł Karaś on 28/12/2022.
//

import Foundation
import SwiftUI
import Security

import Foundation
import Security

let keychainService = Bundle.main.bundleIdentifier // replace with your app's unique identifier

// Store data in the keychain
func storeDataInKeychain(_ key: String, data: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainService!,
        kSecAttrAccount as String: key,
        kSecValueData as String: data.data(using: .utf8)!
    ]
    let status = SecItemAdd(query as CFDictionary, nil)
    if status != errSecSuccess {
        print("Error storing data in keychain: \(status)")
    }
}

// Retrieve data from the keychain
func getDataFromKeychain(_ key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainService!,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecSuccess {
        if let res = result as? Data {
            return String(decoding: res, as: UTF8.self)
        } else {
            return nil
        }
    } else if status == errSecItemNotFound {
        return nil
    } else {
        print("Error retrieving data from keychain: \(status)")
        return nil
    }
}

// Test the functions
//let testData = "This is a test".data(using: .utf8)!
//storeDataInKeychain(data: testData)
//if let retrievedData = getDataFromKeychain() {
//    print(String(data: retrievedData, encoding: .utf8)!)
//} else {
//    print("Data not found in keychain")
//}

enum OandaMode {
    case FXTrader
    case FXPractice
}

func modeToValue(_ mode: OandaMode) -> String {
    switch mode {
    case .FXTrader:
        return "fxt"
    case .FXPractice:
        return "fxp"
    }
}

func valueToMode(_ value: String) -> OandaMode {
    switch value {
    case "fxt":
        return OandaMode.FXTrader
    default:
        return OandaMode.FXPractice
    }
}

struct CreatingPhase: View {
    @Binding var state: AppState
    @Binding var candles: Candles
    @Binding var progress: Double
    @State var from = Date()
    @State var to = Date()
    @State var granularity = "M1"
    @State var instrument = "GBP_USD"
    @State var token = getDataFromKeychain("token") ?? ""
    @State var mode = valueToMode(getDataFromKeychain("mode") ?? "fxt")
    
    var body: some View {
        VStack {
            Text("Specify the configuration").font(.largeTitle).padding()
            HStack {
                SecureField("Your API Token", text: $token).frame(width: 200)
                Picker("Choose mode", selection: $mode) {
                    Text("FX Trade").tag(OandaMode.FXTrader)
                    Text("FX Practice").tag(OandaMode.FXPractice)
                }.frame(width: 200)
            }
            HStack {
                TextField("Granularity", text: $granularity).frame(width: 50)
                TextField("Instrument", text: $instrument).frame(width: 100)
            }
            HStack{
                DatePicker(
                    "From",
                    selection: $from,
                    displayedComponents: [.date]
                ).datePickerStyle(.graphical).frame(width: 200)
                DatePicker(
                    "To",
                    selection: $to,
                    displayedComponents: [.date]
                ).datePickerStyle(.graphical).frame(width: 200)
            }.padding()
            Button(action: {
                storeDataInKeychain("token", data: self.token)
                storeDataInKeychain("mode", data: modeToValue(self.mode))
                self.state = .Fetching
                Task {
                    let result = await self.candles.fetchCandles(
                        from: self.from,
                        to: self.to,
                        granularity: self.granularity,
                        instrument: self.instrument,
                        api_key: self.token,
                        mode: self.mode,
                        cb: { value in
                            DispatchQueue.main.async {
                                self.progress = value
                            }
                        }
                    )
                    if result {
                        self.state = .Success
                    } else {
                        print(self.candles.candles!)
                        self.state = .Error
                    }
                }
            }) { Text("Submit") }
        }.padding()
    }
}
