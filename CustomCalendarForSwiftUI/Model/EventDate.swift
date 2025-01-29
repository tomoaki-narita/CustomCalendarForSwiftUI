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
    
    func toDictionary() -> [String: Any] {
            return [
                "id": id,
                "eventTitle": eventTitle,
                "eventStartDate": eventStartDate,
                "eventEndDate": eventEndDate,
                "eventMemo": eventMemo ?? "",
                "allDay": allDay,
                "colorData": colorData?.base64EncodedString() ?? "",
                "sortOrder": sortOrder
            ]
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
    
    func toDictionary() -> [String: Any] {
            let dateFormatter = ISO8601DateFormatter()
            return [
                "id": id,
                "eventTitle": eventTitle,
                "eventStartDate": dateFormatter.string(from: eventStartDate),
                "eventEndDate": dateFormatter.string(from: eventEndDate),
                "eventMemo": eventMemo ?? "",
                "allDay": allDay,
                "colorData": colorData?.base64EncodedString() ?? "",
                "sortOrder": sortOrder
            ]
        }
    
}

class EventViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    private var realm: Realm
    init() {
        realm = try! Realm() // Realmの初期化
        fetchEvents()
    }
    
    //Realmからデータを取得して@Publishedに反映
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
    
    func deleteEvent(_ event: CalendarEvent) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(event)
            print("削除されました")
        }
        fetchEvents() // データを再読み込みして更新
    }
    
//    func deleteAllEvents() {
//        do {
//            let realm = try Realm()
//            try realm.write {
//                // イベントが無効化されていないことを確認
//                let validEvents = realm.objects(CalendarEvent.self).filter { $0.isInvalidated == false }
//                realm.delete(validEvents) // 無効でないイベントだけを削除
//            }
//            print("全てのイベントが削除されました")
//            fetchEvents() // 削除後にリストを更新
//        } catch {
//            print("全てのイベントの削除に失敗しました: \(error.localizedDescription)")
//        }
//    }
}
