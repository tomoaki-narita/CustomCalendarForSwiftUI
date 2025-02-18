//
//  UserSettings.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/02/12.
//

import SwiftUI
import RealmSwift

enum AppColorTheme: String, CaseIterable, Identifiable {
    case dark, light, red, orange, yellow, green, blue, purple, pink, brown, gray, darkXpurple, system, blueGradient

    var id: String { self.rawValue }

    var primaryColor: Color {
        switch self {
        case .dark: return Color("DarkPrimary")
        case .light: return Color("LightPrimary")
        case .red: return Color("RedPrimary")
        case .orange: return Color("OrangePrimary")
        case .yellow: return Color("YellowPrimary")
        case .green: return Color("GreenPrimary")
        case .blue: return Color("BluePrimary")
        case .purple: return Color("PurplePrimary")
        case .pink: return Color("PinkPrimary")
        case .brown: return Color("BrownPrimary")
        case .gray: return Color("GrayPrimary")
        case .darkXpurple: return Color("DarkXPurplePrimary")
        case .system: return Color("SystemPrimary")
        case .blueGradient: return Color("BluePrimary")
        }
    }

    var secondaryColor: Color {
        switch self {
        case .dark: return Color("DarkSecondary")
        case .light: return Color("LightSecondary")
        case .red: return Color("RedSecondary")
        case .orange: return Color("OrangeSecondary")
        case .yellow: return Color("YellowSecondary")
        case .green: return Color("GreenSecondary")
        case .blue: return Color("BlueSecondary")
        case .purple: return Color("PurpleSecondary")
        case .pink: return Color("PinkSecondary")
        case .brown: return Color("BrownSecondary")
        case .gray: return Color("GraySecondary")
        case .darkXpurple: return Color("DarkXPurpleSecondary")
        case .system: return Color("SystemSecondary")
        case .blueGradient: return Color("GrayOpacity")
        }
    }
    
    var tertiaryColor: Color {
        switch self {
        case .dark: return Color("DarkTertiary")
        case .light: return Color("LightTertiary")
        case .red: return Color("RedTertiary")
        case .orange: return Color("OrangeTertiary")
        case .yellow: return Color("YellowTertiary")
        case .green: return Color("GreenTertiary")
        case .blue: return Color("BlueTertiary")
        case .purple: return Color("PurpleTertiary")
        case .pink: return Color("PinkTertiary")
        case .brown: return Color("BrownTertiary")
        case .gray: return Color("GrayTertiary")
        case .darkXpurple: return Color("DarkXPurpleTertiary")
        case .system: return Color("SystemTertiary")
        case .blueGradient: return Color("BlueTertiary")
        }
    }
    
    var gradientColor: Color {
        switch self {
        case .dark: return Color("DarkPrimary")
        case .light: return Color("LightPrimary")
        case .red: return Color("RedPrimary")
        case .orange: return Color("OrangePrimary")
        case .yellow: return Color("YellowPrimary")
        case .green: return Color("GreenPrimary")
        case .blue: return Color("BluePrimary")
        case .purple: return Color("PurplePrimary")
        case .pink: return Color("PinkPrimary")
        case .brown: return Color("BrownPrimary")
        case .gray: return Color("GrayPrimary")
        case .darkXpurple: return Color("DarkXPurplePrimary")
        case .system: return Color("SystemPrimary")
        case .blueGradient: return Color("PurplePrimary")
        }
    }
}

class AppThemeManager: ObservableObject {
    @Published var currentTheme: AppColorTheme
    
    init() {
        let savedTheme = UserSettings.getCurrentSettings().selectedTheme
        print("Saved Theme:", savedTheme)  // デバッグログを表示

        if let theme = AppColorTheme(rawValue: savedTheme), !savedTheme.isEmpty {
            self.currentTheme = theme
        } else {
            self.currentTheme = .dark
            UserSettings.updateTheme(.dark)
        }
    }

    
    func changeTheme(to newTheme: AppColorTheme) {
        currentTheme = newTheme
        UserSettings.updateTheme(newTheme)
    }
}


class UserSettings: Object {
    @Persisted var selectedTheme: String = AppColorTheme.dark.rawValue

    static func getCurrentSettings() -> UserSettings {
        let realm = try! Realm()
        if let settings = realm.objects(UserSettings.self).first {
            return settings
        } else {
            let newSettings = UserSettings()
            newSettings.selectedTheme = AppColorTheme.dark.rawValue  // 明示的に.darkを設定
            try! realm.write {
                realm.add(newSettings)
            }
            return newSettings
        }
    }



    static func updateTheme(_ theme: AppColorTheme) {
        let realm = try! Realm()
        let settings = getCurrentSettings()
        try! realm.write {
            settings.selectedTheme = theme.rawValue
        }
    }
}

extension View {
    @available(iOS 14, *)
    func navigationBarTitleTextColor(_ color: Color) -> some View {
        let uiColor = UIColor(color)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: uiColor ]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: uiColor ]
        return self
    }
}
