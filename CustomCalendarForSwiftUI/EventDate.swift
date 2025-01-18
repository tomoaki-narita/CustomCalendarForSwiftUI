//
//  EventDate.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2024/12/29.
//

import SwiftUI
import RealmSwift

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

//class EventDateMapping: Object, Identifiable {
//    @Persisted(primaryKey: true) var id: String
//    @Persisted var date: String // 紐付ける日付（フォーマット: "yyyy-MM-dd"）
//    @Persisted var event: EventDate // 紐付けられるイベント
//
//    // 初期化
//    convenience init(date: String, event: EventDate, id: String = UUID().uuidString) {
//        self.init()
//        self.id = id
//        self.date = date
//        self.event = event
//    }
//}

