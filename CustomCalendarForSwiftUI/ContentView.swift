//
//  ContentView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2024/12/27.
//

import SwiftUI
import RealmSwift

struct ContentView: View {
    @State private var currentMonth: Int = 0
    @State private var selectedDates: [Date] = []
    @State private var selectedEvent: EventDate?
    @State private var isPickerVisible: Bool = false
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var showEventPickerView: Bool = false
    @State private var activeAlert: AlertType? = nil
    @State private var isReloadButton: Bool = false
    @State private var isPlusButton: Bool = false
    @State private var showConfirmationDialog: Bool = false
    @State private var eventToProcess: EventDate?
    private let calendar = Calendar.current
    @ObservedResults(EventDate.self, sortDescriptor: SortDescriptor(keyPath: "sortOrder", ascending: true)) var events
    @StateObject private var eventViewModel = EventViewModel()
    
    @State private var tappedDate: Date? = nil  // ロングタップされた日付
    
    private enum AlertType: Identifiable {
        case noDateSelected
        case custom(String)
        
        var id: String {
            switch self {
            case .noDateSelected:
                return "No date selected"
            case .custom(let message):
                return message
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                //                Color(.secondarySystemGroupedBackground).ignoresSafeArea()
                VStack {
                    CalendarView(
                        currentMonth: $currentMonth,
                        selectedDates: $selectedDates,
                        isPickerVisible: $isPickerVisible,
                        selectedYear: $selectedYear,
                        selectedMonth: $selectedMonth,
                        events: eventViewModel.events,
                        onLongTap: { date in
                            tappedDate = date  // ロングタップされた日付を保存
                        }
                    )
                    //                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .blur(radius: showEventPickerView ? 2.5 : 0)
                    .allowsHitTesting(!showEventPickerView)
                    
                    
                    
                    HStack {
                        Spacer()
                        Button(action:{
                            isReloadButton.toggle()
                            resetCalendar()
                        }) {
                            
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                                .foregroundStyle(Color.primary)
                                .font(.title3).fontWeight(.bold)
                                .padding()
                                .shadow(radius: 10)
                        }
                        .symbolEffect(.bounce.down.wholeSymbol, value: isReloadButton)
                        .disabled(isPickerVisible)
                        Spacer()
                        Button(action: {
                            isPlusButton.toggle()
                            if selectedDates == [] {
                                activeAlert = .noDateSelected
                            } else {
                                withAnimation(.snappy(duration: 0.5)) {
                                    showEventPickerView.toggle()
                                }
                            }
                            
                        }) {
                            Image(systemName: "plus")
                                .foregroundStyle(Color.primary)
                                .font(.title2).fontWeight(.bold)
                                .padding()
                                .shadow(radius: 10)
                        }
                        .symbolEffect(.bounce.down.wholeSymbol, value: isPlusButton)
                        
                        Spacer()
                        NavigationLink(destination: EditView()) {
                            
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(Color.primary)
                                .font(.title3).fontWeight(.bold)
                                .padding()
                                .shadow(radius: 10)
                            
                        }
                        Spacer()
                        
                        
                        Button("print") {
                            fetchAndPrintSavedEvents()
                        }
                        // 全削除ボタン
                        Button(action: deleteAllEvents) {
                            Text("delete")
                            
                        }
                        
                        
                        
                    }
                    
                    //                        .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .allowsHitTesting(!showEventPickerView) //opacityが0になるとタップできなくなるため不要だが一応残す
                    .opacity(showEventPickerView ? 0 : 1)
                    
                }
                .padding()
                .sheet(item: $tappedDate) { date in
                    EventDetailModal(date: date, events: eventViewModel.events)
                        .presentationDetents([.medium, .large])
                }
            }
        }
        .overlay {
            if showEventPickerView {
                EventPickerView(
                    selectedEvent: $selectedEvent,
                    events: Array(events)
                ) {
                    withAnimation(.snappy(duration: 1.5)) {
                        showEventPickerView = false
                    }
                } onEventSelected: { event in
                    // イベント選択時にダイアログを表示
                    eventToProcess = event
                    showConfirmationDialog = true
                }
                .transition(.move(edge: .bottom))
            }
        }
        .confirmationDialog(
            "\(eventToProcess?.eventTitle ?? "event title")",
            isPresented: $showConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("OK", role: .none) {
                if let event = eventToProcess {
                    processEvent(event)
                    selectedDates.removeAll() // 選択を解除
                    selectedEvent = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to register for the date of your choice?")
        }
        .alert(item: $activeAlert, content: createAlert)
    }
    
    private func resetCalendar() {
        currentMonth = 0 // 現在の月に戻す
        selectedDates.removeAll() // 選択を解除
        selectedEvent = nil
        isPickerVisible = false // ピッカーを閉じる
        // Pickerの値を現在の年月にリセット
        let currentDate = Date()
        let currentYear = Calendar.current.component(.year, from: currentDate)
        let currentMonthValue = Calendar.current.component(.month, from: currentDate)
        // Pickerの状態をリセット
        selectedYear = currentYear
        selectedMonth = currentMonthValue
    }
    
    func decodeDataToColor(_ data: Data?) -> Color {
        guard let data = data,
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return .gray
        }
        return Color(uiColor)
    }
    
    private func createAlert(for alertType: AlertType) -> Alert {
        switch alertType {
        case .noDateSelected:
            return Alert(title: Text(alertType.id), message: Text("Please select a date."), dismissButton: .default(Text("OK")))
            
        case .custom(let message):
            return Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
        }
    }
    
    func combineDateAndTime(dateString: String, timeString: String) -> Date? {
        // 結合したフォーマット例: "2025-01-31 20:44:00"
        let combinedString = "\(dateString) \(timeString)"
        
        // DateFormatterの設定
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm" // 秒を含めたフォーマットに変更
        formatter.locale = Locale(identifier: "en_US_POSIX") // 安定したパースのための設定
        
        // Date型に変換
        return formatter.date(from: combinedString)
    }
    
    /// イベントを処理する関数
    private func processEvent(_ event: EventDate) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let selectedDatesStrings = selectedDates.map { formatter.string(from: $0) }
        
        let eventStartTime = event.eventStartDate
        let eventEndTime = event.eventEndDate
        
        for dateString in selectedDatesStrings {
            guard let combinedStartDate = combineDateAndTime(dateString: dateString, timeString: eventStartTime) else {
                print("開始日時の変換に失敗しました")
                continue
            }
            
            guard let combinedEndDate = combineDateAndTime(dateString: dateString, timeString: eventEndTime) else {
                print("終了日時の変換に失敗しました")
                continue
            }
            
            print("開始日時: \(event.eventTitle) - \(combinedStartDate)")
            print("終了日時: \(event.eventTitle) - \(combinedEndDate)")
            
            let calendarEvent = CalendarEvent(
                eventTitle: event.eventTitle,
                eventStartDate: combinedStartDate,
                eventEndDate: combinedEndDate,
                eventMemo: event.eventMemo,
                allDay: event.allDay,
                sortOrder: event.sortOrder,
                colorData: event.colorData
            )
            eventViewModel.addEvent(calendarEvent)
        }
    }
    
    func saveEventToRealm(event: CalendarEvent) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(event)
            }
            print("イベントが正常に保存されました: \(event.eventTitle)")
            resetCalendar()
        } catch {
            print("イベントの保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func fetchAndPrintSavedEvents() {
        do {
            let realm = try Realm()
            let savedEvents = realm.objects(CalendarEvent.self) // データを全件取得
            
            for event in savedEvents {
                print("イベントID: \(event.id)")
                print("タイトル: \(event.eventTitle)")
                print("開始日時: \(event.eventStartDate)")
                print("終了日時: \(event.eventEndDate)")
                print("メモ: \(event.eventMemo ?? "なし")")
                print("終日: \(event.allDay)")
                print("ソート順: \(event.sortOrder)")
                print("イベントカラー: \(event.colorData ?? Data())")
                print("--------------------------")
            }
        } catch {
            print("データの取得に失敗しました: \(error.localizedDescription)")
        }
    }
    private func deleteAllEvents() {
        eventViewModel.deleteAllEvents()
        resetCalendar()
    }
}

extension Date: @retroactive Identifiable {
    public var id: String {
        return String(self.timeIntervalSince1970)
    }
}

#Preview {
    ContentView()
}
