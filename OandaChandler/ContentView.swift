//
//  ContentView.swift
//  TradingCronical
//
//  Created by Paweł Karaś on 27/12/2022.
//

import SwiftUI
import AppKit

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
    @State var candles = Candles()
    
    var body: some View {
        ZStack {
            switch state {
            case .Creating:
                CreatingPhase(state: $state, candles: $candles, progress: $downloadProgress)
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
                                        try self.candles.generateCSV(save) { value in
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
                            self.candles.candles = nil
                        }) { Text("Back") }.padding().disabled(isSavingFile)
                    }
                }
            case .Error:
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .padding()
                    Text("Could not download the data")
                    Text(self.candles.error ?? "[unknown reason]").monospaced().padding()
                    Button(action: {
                        self.state = .Creating
                        self.candles.candles = nil
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
