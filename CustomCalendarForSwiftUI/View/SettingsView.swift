//
//  SettingsView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/02/17.
//

import SwiftUI
import EventKit

struct SettingsView: View {
    
    @EnvironmentObject var themeManager: AppThemeManager
    @State private var isAuthorized = false
    @State private var isShowDeniedAlert = false
    private let eventStore = EKEventStore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color: themeManager.currentTheme.primaryColor, location: 0.25), .init(color: themeManager.currentTheme.gradientColor, location: 0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                List {
                    Section {
                        NavigationLink("\(themeManager.currentTheme)", destination: ThemeSelectionView())
                            .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            .textCase(.uppercase)
                    } header: {
                        Text("Theme")
                            .fontWeight(.semibold)
                            .font(.headline)
                            .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                    }
                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                    
                    Section {
                        NavigationLink("Export and Import", destination: BackupView())
                            .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            
                    } header: {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.headline)
                            Text("Backup")
                                .fontWeight(.semibold)
                                .font(.headline)
                        }
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                    }
                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                    
                    Section {
                        if isAuthorized {
                            NavigationLink("Export to iOS calendar", destination: CopyingIosCalendarEvents())
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                        } else {
                            HStack {
                                Button("No access rights") {
                                    requestCalendarAccess()
                                }
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                                Spacer()
                                Image(systemName: "gear")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "arrow.up")
                                .font(.headline)
                            Text("iOS Calendar")
                                .fontWeight(.semibold)
                                .font(.headline)
                        }
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                    }
                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                }
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Settings")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(themeManager.currentTheme.tertiaryColor)
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(themeManager.currentTheme.primaryColor), for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .listStyle(.sidebar)
                .headerProminence(.increased)
                .navigationBarBackButtonTextHidden()
            }
        }
        .onAppear {
            isAuthorized = authorizationStatus()
        }
        .alert("Permission is required to access the calendar.", isPresented: $isShowDeniedAlert) {
            Button("Close", role: .cancel) {}
            Button("Settings App") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        } message: {
            Text("This app requires permission to access your calendar.")
        }
    }
    
    func requestCalendarAccess() {
            if #available(iOS 17.0, *) {
                eventStore.requestWriteOnlyAccessToEvents { granted, error in
                    DispatchQueue.main.async {
                        if granted || self.authorizationStatus() {
                            isAuthorized = true // 許可が取れたら NavigationLink に変更
                        } else {
                            eventStore.requestFullAccessToEvents { granted, error in
                                DispatchQueue.main.async {
                                    if granted {
                                        isAuthorized = true
                                    } else {
                                        isShowDeniedAlert = true
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            isAuthorized = true
                        } else {
                            isShowDeniedAlert = true
                        }
                    }
                }
            }
        }

        func authorizationStatus() -> Bool {
            let status = EKEventStore.authorizationStatus(for: .event)
            return status == .fullAccess || status == .writeOnly
        }
}

#Preview {
    SettingsView()
        .environmentObject(AppThemeManager())
}
