//
//  CustomCalendarForSwiftUIApp.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2024/12/27.
//

import SwiftUI
import RealmSwift

@main
struct CustomCalendarForSwiftUI: SwiftUI.App {  // Appという名前をCustomCalendarAppに変更
    @StateObject var themeManager = AppThemeManager()
    init() {
        // マイグレーション設定
        let config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    
                    migration.enumerateObjects(ofType: EventDate.className()) { _, newObject in
                        newObject?["sortOrder"] = 0 // 初期値を設定
                    }
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(themeManager)
        }
    }
}

