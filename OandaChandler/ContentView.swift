//
//  ContentView.swift
//  TradingCronical
//
//  Created by Paweł Karaś on 27/12/2022.
//

import SwiftUI
import AppKit
import Charts

func showSavePanel() -> URL? {
    let savePanel = NSSavePanel()
    savePanel.allowedContentTypes = [.delimitedText]
    savePanel.canCreateDirectories = true
    savePanel.isExtensionHidden = false
    savePanel.allowsOtherFileTypes = false
    savePanel.title = "Save your text"
    savePanel.message = "Choose a folder and a name to store your text."
    savePanel.nameFieldLabel = "File name:"
    let response = savePanel.runModal()
    return response == .OK ? savePanel.url : nil
}

enum AppState {
    case Creating
    case Fetching
    case Success
    case Error
}

enum SavingFileState {
    case NotSaving
    case Saving
    case Saved
}

struct ContentView: View {
    @State var state = AppState.Creating
    @State var downloadProgress = 0.0
    @State var saveProgress = 0.0
    @State var isSavingFile = false
    @State var candles: [Candle] = []
    @State var error: String? = nil
    
    func getPricing(candle: Candle) -> CandlePricing {
        return (candle.mid ?? candle.bid ?? candle.ask)!
    }
    
    func generateCSV(_ url: URL, callback: (Double) -> Void) throws {
        var row = ""
        for (index, candle) in self.candles.enumerated() {
            let pricing = getPricing(candle: candle)
            row += [
                formatDateString(candle.time),
                pricing.o,
                pricing.h,
                pricing.l,
                pricing.c,
                String(candle.volume)
            ].joined(separator: ",") + "\n"
            if index % 100 == 0 {
                callback(Double(index) / Double(self.candles.count))
            }
        }
        try row.data(using: .utf8)!.write(to: url)
    }
    
    var body: some View {
        ZStack {
            switch state {
            case .Creating:
                CreatingView(state: $state, candles: $candles, error: $error, progress: $downloadProgress)
            case .Fetching:
                ProgressView(value: downloadProgress, label: {
                    Text("Downloading...")
                }).progressViewStyle(CircularProgressViewStyle(tint: .orange))
            case .Success:
                VStack {
                    Text("Download completed")
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .foregroundColor(.green)
                        .frame(width: 50, height: 50)
                        .padding()
                    HStack {
                        Button(action: {
                            let backgroundQueue = DispatchQueue.global(qos: .background)
                            if let save = showSavePanel() {
                                isSavingFile = true
                                backgroundQueue.async {
                                    do {
                                        try self.generateCSV(save) { value in
                                            DispatchQueue.main.async {
                                                self.saveProgress = value
                                            }
                                        }
                                        // Complete after one second
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            saveProgress = 1.0
                                            // Hide after 2 seconds
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                isSavingFile = false
                                            }
                                        }
                                    } catch {
                                        print("Could not save the file")
                                    }
                                }
                            }
                        }) { Text("Save to CSV") }.padding().disabled(isSavingFile).popover(isPresented: $isSavingFile) {
                            VStack {
                                if saveProgress > 0.99 {
                                    HStack {
                                        Text("Saved")
                                        Image(systemName: "checkmark.circle")
                                            .resizable()
                                            .foregroundColor(.green)
                                            .frame(width: 20, height: 20)
                                    }
                                } else {
                                        Text("Saving...")
                                    ProgressView(value: saveProgress).frame(width: 100).tint(.orange)
                                }
                            }.padding().interactiveDismissDisabled()
                        }
                        Button(action: {
                            self.state = .Creating
                            self.candles = []
                        }) { Text("Back") }.padding().disabled(isSavingFile)
                    }
                    let chartCandles = stride(from: 0, to: candles.count, by: candles.count / 100).map { candles[$0] }
                    let minSeries = chartCandles.map { Double(getPricing(candle: $0).l)! }.min()!
                    let maxSeries = chartCandles.map { Double(getPricing(candle: $0).h)! }.max()!
                    Chart {
                        ForEach(chartCandles, id: \.self.time) { candle in
                            LineMark(
                                x: .value("Time", Date.dateFromISOString(string: candle.time)!, unit: .minute),
                                y: .value("Low Price", Double(getPricing(candle: candle).c)!)
                            )
                            .foregroundStyle(Color("AccentColor").gradient)
                        }
                    }
                    .chartYScale(domain: minSeries...maxSeries)
                    .padding()
                }
            case .Error:
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .padding()
                    Text("Could not download the data")
                    Text(self.error ?? "[unknown reason]").monospaced().padding()
                    Button(action: {
                        self.state = .Creating
                        self.candles = []
                    }) { Text("Back") }.padding()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
