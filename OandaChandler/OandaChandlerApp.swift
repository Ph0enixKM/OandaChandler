//
//  TradingCronicalApp.swift
//  TradingCronical
//
//  Created by Paweł Karaś on 27/12/2022.
//

import SwiftUI

@main
struct TradingCronicalApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                LinearGradient(colors: [
                    Color(red: 95/255, green: 42/255, blue: 0),
                    Color(red: 40/255, green: 17/255, blue: 0)
                ], startPoint: .topLeading, endPoint: .bottom)
                ContentView()
            }.edgesIgnoringSafeArea(.all)
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
}
