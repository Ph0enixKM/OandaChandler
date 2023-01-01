//
//  Auth.swift
//  OandaChandler
//
//  Created by Paweł Karaś on 01/01/2023.
//

import Foundation

class AuthData: ObservableObject {
    @Published var token = getDataFromKeychain("token") ?? "";
    @Published var mode = valueToMode(getDataFromKeychain("mode") ?? "fxt")
    @Published var accountId: String? = getDataFromKeychain("accountId")
    
    func updateAccountId() {
        Task {
            let value = try await Request(self).getAccount()
            DispatchQueue.main.async {
                self.accountId = value
                if let id = value {
                    storeDataInKeychain("accountId", data: id)
                }
            }
        }
    }
    
    func modeToUrl() -> String {
        switch mode {
        case .FXTrade:
            return "fxtrade"
        case .FXPractice:
            return "fxpractice"
        }
    }
}
