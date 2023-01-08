import SwiftUI

enum SideBarItem: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    
    case export = "Export"
    case auth = "Authenticate"
}

func sideBarIcon(_ item: SideBarItem) -> String {
    switch item {
    case .export:
        return "square.and.arrow.down"
    case .auth:
        return "key"
    }
}


@main
struct TradingCronicalApp: App {
    @State var sideBarVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State var selected = getDataFromKeychain("token") != nil ? SideBarItem.export : SideBarItem.auth
    @StateObject var authData = AuthData();
    @State var granuality = Granularity.m1
    @State var instruments = []
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Background()
                NavigationSplitView(columnVisibility: $sideBarVisibility) {
                    List(SideBarItem.allCases, selection: $selected) { item in
                        NavigationLink(value: item) {
                            Image(systemName: sideBarIcon(item)).foregroundColor(.accentColor)
                            Text(item.rawValue.localizedCapitalized)
                        }.disabled(self.authData.accountId == nil && item == .export)
                    }
                } detail: {
                    switch selected {
                    case .auth:
                        Auth()
                            .environmentObject(authData)
                            .frame(maxHeight: .infinity, alignment: .top)
                    case .export:
                        ContentView()
                            .environmentObject(authData)
                    }
                }
                .onAppear {
                    if authData.accountId == nil {
                        selected = SideBarItem.auth
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .toolbar {
                ToolbarItemGroup(placement: .navigation, content: {
                    Button(action: {
                        self.authData.updateAccountId()
                    }, label: {
                        if self.authData.accountId != nil {
                            Image(systemName: "wifi")
                        } else {
                            Image(systemName: "wifi.slash")
                        }
                    }).help("Reconnect")
                        .animation(.default, value: self.authData.accountId)
                        .onAppear(perform: self.authData.updateAccountId)
                })
            }
        }.windowStyle(.hiddenTitleBar)
            .windowToolbarStyle(.unified)
    }
}
