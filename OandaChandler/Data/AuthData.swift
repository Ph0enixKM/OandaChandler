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
    @Published var account_id: String? = nil
    
    func updateAccountId() {
        Task {
            self.account_id = try await Request(self).getAccount()
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
