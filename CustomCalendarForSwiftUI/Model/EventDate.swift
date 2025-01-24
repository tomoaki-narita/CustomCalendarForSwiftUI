//
//  EventDate.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2024/12/29.
//

import SwiftUI
import RealmSwift

//イベント作成時のテンプレートモデル
class EventDate: Object, Identifiable {
    
    @Persisted(primaryKey: true) var id: String
    @Persisted var eventTitle: String
    @Persisted var eventStartDate: String
    @Persisted var eventEndDate: String
    @Persisted var eventMemo: String?
    @Persisted var allDay: Bool
    @Persisted var colorData: Data?
    @Persisted var sortOrder: Int // 並び順を保持するプロパティ
    var frame: CGRect = .zero
    
    // 初期化
    convenience init(
        eventTitle: String,
        eventStartDate: String,
        eventEndDate: String,
        eventMemo: String?,
        allDay: Bool,
        id: String = UUID().uuidString,
        sortOrder: Int? = nil,  // デフォルト値をnilに変更
        colorData: Data? = nil
    ) {
        self.init()
        self.id = id
        self.eventTitle = eventTitle
        self.eventStartDate = eventStartDate
        self.eventEndDate = eventEndDate
        self.eventMemo = eventMemo
        self.allDay = allDay
        self.colorData = colorData
        self.sortOrder = sortOrder ?? 0  // sortOrderがnilの場合に0を設定
    }
    
}

//カレンダーにイベントを登録する際に仕様するモデル。Realmに保存する際に階層を分けるためにモデルを別に。
class CalendarEvent: Object, Identifiable {
    
    @Persisted(primaryKey: true) var id: String
    @Persisted var eventTitle: String
    @Persisted var eventStartDate: Date
    @Persisted var eventEndDate: Date
    @Persisted var eventMemo: String?
    @Persisted var allDay: Bool
    @Persisted var colorData: Data?
    @Persisted var sortOrder: Int // 並び順を保持するプロパティ
    var frame: CGRect = .zero
    
    // 初期化
    convenience init(
        eventTitle: String,
        eventStartDate: Date,
        eventEndDate: Date,
        eventMemo: String? = nil,
        allDay: Bool,
        id: String = UUID().uuidString,
        sortOrder: Int? = nil,
        colorData: Data? = nil
    ) {
        self.init()
        self.id = id
        self.eventTitle = eventTitle
        self.eventStartDate = eventStartDate
        self.eventEndDate = eventEndDate
        self.eventMemo = eventMemo
        self.allDay = allDay
        self.colorData = colorData
        self.sortOrder = sortOrder ?? 0
    }
}

class EventViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    
    init() {
        fetchEvents()
    }
    
    // Realmからデータを取得して@Publishedに反映
    func fetchEvents() {
        do {
            let realm = try Realm()
            let results = realm.objects(CalendarEvent.self)
            events = Array(results) // Realmオブジェクトを配列に変換
        } catch {
            print("イベントの取得に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // イベントを追加
    func addEvent(_ event: CalendarEvent) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(event)
            }
            print("イベントが正常に保存されました: \(event.eventTitle)")
            fetchEvents() // 保存後にリストを更新
        } catch {
            print("イベントの保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // 全てのイベントを削除
    func deleteAllEvents() {
        do {
            let realm = try Realm()
            let allEvents = realm.objects(CalendarEvent.self)
            try realm.write {
                realm.delete(allEvents)
            }
            print("すべてのイベントを削除しました")
            fetchEvents() // 削除後にリストを更新
        } catch {
            print("イベントの削除に失敗しました: \(error.localizedDescription)")
        }
    }
}
