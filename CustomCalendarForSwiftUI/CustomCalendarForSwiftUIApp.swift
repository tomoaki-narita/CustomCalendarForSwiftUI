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
    
    init() {
        // マイグレーション設定
        let config = Realm.Configuration(
            schemaVersion: 2, // スキーマバージョンを指定 (1 から 2 に変更)
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // sortOrderプロパティを追加
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
            ContentView()
        }
    }
}

