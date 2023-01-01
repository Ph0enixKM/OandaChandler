//
//  Auth.swift
//  OandaChandler
//
//  Created by Paweł Karaś on 31/12/2022.
//

import Foundation
import SwiftUI

struct Auth: View {
    @EnvironmentObject var authData: AuthData
    @FocusState var isTokenFocused: Bool
    
    func getAccountId() {
        Task {
            authData.account_id = try await Request(authData).getAccount()
        }
    }
    
    var body: some View {
        VStack {
            Image(systemName: "key.viewfinder")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.accentColor)
                .padding()
            Text("Oanda API Token").font(.largeTitle)
                .padding(.bottom)
            VStack {
                HStack {
                    SecureField("Insert here your Oanda API Token", text: $authData.token)
                        .focused($isTokenFocused).onChange(of: authData.token) { item in
                            storeDataInKeychain("token", data: authData.token)
                            getAccountId()
                        }.frame(width: 200)
                    Picker("", selection: $authData.mode) {
                        Text("FX Trade").tag(OandaMode.FXTrade)
                        Text("FX Practice").tag(OandaMode.FXPractice)
                    } .onChange(of: authData.mode) { mode in
                        storeDataInKeychain("mode", data: modeToValue(authData.mode))
                        getAccountId()
                    }.frame(width: 200)
                }
                Text("The api token will be stored securely in your keychain.").font(.footnote)
            }
        }
    }
}

struct Auth_Previews: PreviewProvider {
    static var previews: some View {
        Auth()
    }
}
