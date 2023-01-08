//
//  Background.swift
//  OandaChandler
//
//  Created by Paweł Karaś on 08/01/2023.
//

import Foundation
import SwiftUI

struct Background: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // Background Gradient
        switch colorScheme {
        case .dark:
            LinearGradient(colors: [
                Color(red: 95/255, green: 42/255, blue: 0),
                Color(red: 40/255, green: 17/255, blue: 0)
            ], startPoint: .topLeading, endPoint: .bottom)
        case .light:
            LinearGradient(colors: [
                Color(red: 255/255, green: 216/255, blue: 185/255),
                Color(red: 255/255, green: 180/255, blue: 110/255)
            ], startPoint: .topLeading, endPoint: .bottom)
        default:
            EmptyView()
        }
    }
}
