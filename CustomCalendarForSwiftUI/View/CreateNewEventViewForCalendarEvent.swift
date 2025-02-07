//
//  CreateNewEventViewForCalendarEvent.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/02/09.
//

import SwiftUI
import RealmSwift

struct CreateNewEventViewForCalendarEvent: View {
    
    @Binding var editingEvent: CalendarEvent?
    @State var eventTitle: String = ""
    @State var eventMemo: String = ""
    @State var eventStartDate: Date = Date()
    @State var eventEndDate: Date = Date()
    @State var allDayToggle: Bool = false
    @State var selectedColor: Color
    @State private var activeAlert: AlertType? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusdFieldForEventTitleTextField: Field?
    @FocusState private var focusdFieldForEventMemoTextField: Field?
    let starImage: Image = Image(systemName: "star.fill")
    let textImage: Image = Image(systemName: "t.square")
    let clockImage: Image = Image(systemName: "clock")
    let memoImage: Image = Image(systemName: "note.text")
    let colorImage: Image = Image(systemName: "swatchpalette")
    let selectedDate: Date
    
    private enum Field: Hashable {
        case eventName
        case eventMemo
    }
    
    private enum AlertType: Identifiable {
        case emptyTitle
        case invalidDateRange
        case custom(String)
        
        var id: String {
            switch self {
            case .emptyTitle:
                return "emptyTitle"
            case .invalidDateRange:
                return "invalidDateRange"
            case .custom(let message):
                return message
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(themeManager.currentTheme.primaryColor).ignoresSafeArea()
                List {
                    Section {
                        HStack(alignment: .center) {
                            textImage.font(.footnote)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            Text("Title")
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            Spacer()
                            ZStack(alignment: .leading) {
                                if eventTitle.isEmpty {
                                    Text("Title")
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor.opacity(0.5)))
                                }
                                TextField("", text: $eventTitle, axis: .vertical)
                                    .focused($focusdFieldForEventTitleTextField, equals: Field.eventName)
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            }
                            .padding(.leading)
                            
                            Button {
                                focusdFieldForEventTitleTextField = nil
                                eventTitle = ""
                            } label: {
                                Image(systemName: "delete.left")
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 2)
                            .opacity(eventTitle.isEmpty ? 0 : 1)
                        }
                        .frame(minHeight: 40)
                        
                        HStack {
                            clockImage.font(.footnote)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            DatePicker("Start", selection: $eventStartDate, displayedComponents: [.hourAndMinute])
                                .colorScheme(currentThemeDatePickerColorScheme() ? .dark : .light)
                            //                                .environment(\.locale, .init(identifier: "ja"))
                                .padding(.vertical, 1)
                                .frame(minHeight: 40)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                        }
                        
                        
                        HStack {
                            clockImage.font(.footnote)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            DatePicker("End", selection: $eventEndDate, displayedComponents: [.hourAndMinute])
                                .colorScheme(currentThemeDatePickerColorScheme() ? .dark : .light)
                            //                                .environment(\.locale, .init(identifier: "ja"))
                                .padding(.vertical, 1)
                                .frame(minHeight: 40)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                        }
                        
                        
                        Toggle(isOn: $allDayToggle) {
                            HStack {
                                starImage.font(.footnote)
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                Text("All day")
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            }
                            .frame(minHeight: 40)
                        }
                        
                        HStack {
                            memoImage.font(.footnote)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            Text("Memo")
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            Spacer()
                            
                            ZStack(alignment: .leading) {
                                if eventMemo.isEmpty {
                                    Text("Memo")
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor.opacity(0.5)))
                                }
                                TextField("", text: $eventMemo, axis: .vertical)
                                    .focused($focusdFieldForEventMemoTextField, equals: Field.eventMemo)
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            }
                            .padding(.leading)
                            
                            Button {
                                focusdFieldForEventMemoTextField = nil
                                eventMemo = ""
                            } label: {
                                Image(systemName: "delete.left")
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 2)
                            .opacity(eventMemo.isEmpty ? 0 : 1)
                        }
                        .frame(minHeight: 40)
                        
                        HStack {
                            colorImage.font(.footnote)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            Text("Color")
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            Spacer()
                            ColorPicker("Select color", selection: $selectedColor, supportsOpacity: true)
                                .labelsHidden()
                        }
                        .frame(minHeight: 40)
                    }
                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                    
                    Section {
                        HStack {
                            Spacer()
                            Button(editingEvent == nil ? "Add" : "Save") {
                                handleSaveButtonTapped()
                            }
                            .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            Spacer()
                        }
                    }
                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(editingEvent == nil ? "New event" : "Edit event")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(themeManager.currentTheme.tertiaryColor)
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(themeManager.currentTheme.primaryColor), for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color(themeManager.currentTheme.tertiaryColor).opacity(0.1))
                                    .frame(width: 28)
                            )
                    }
                }
                .onAppear {
                    if let editingEvent = editingEvent {
                        eventTitle = editingEvent.eventTitle
                        eventMemo = editingEvent.eventMemo ?? ""
                        eventStartDate = editingEvent.eventStartDate
                        eventEndDate = editingEvent.eventEndDate
                        allDayToggle = editingEvent.allDay
                        selectedColor = decodeDataToColor(editingEvent.colorData)
                        print("editingEvent!!!\(selectedDate)")
                    } else {
                        print("selectedDate!!!\(selectedDate)")
                            eventStartDate = selectedDate
                            eventEndDate = selectedDate
                        
                    }
                }
                .alert(item: $activeAlert, content: createAlert)
            }
        }
    }
    
    func handleSaveButtonTapped() {
        guard let realm = try? Realm() else { return }

        // タイトルが空の場合
        if eventTitle.isEmpty {
            activeAlert = .emptyTitle
            return
        }

        // 開始日が終了日よりも後になっていないか確認
        if eventEndDate <= eventStartDate {
            activeAlert = .invalidDateRange
            return
        }

        let startDateStr = dateToString(eventStartDate)
        let endDateStr = dateToString(eventEndDate)
        let colorData = encodeColorToData(selectedColor)

        // 重複チェック
        let duplicateEvent = realm.objects(CalendarEvent.self).first {
            $0.eventTitle == eventTitle &&
            dateToString($0.eventStartDate) == startDateStr &&
            dateToString($0.eventEndDate) == endDateStr &&
            $0.colorData == colorData &&
            $0.id != (editingEvent?.id ?? "") // 自身を除外
        }

        if duplicateEvent != nil {
            activeAlert = .custom(String(localized: "This event has already been registered."))
            return
        }

        try? realm.write {
            if let editingEventID = editingEvent?.id,
               let existingEvent = realm.object(ofType: CalendarEvent.self, forPrimaryKey: editingEventID) {
                // 既存イベントの更新
                existingEvent.eventTitle = eventTitle
                existingEvent.eventStartDate = eventStartDate
                existingEvent.eventEndDate = eventEndDate
                existingEvent.eventMemo = eventMemo
                existingEvent.allDay = editingEvent?.allDay ?? allDayToggle
                existingEvent.colorData = colorData
            } else {
                // 新規イベントの作成
                let newEvent = CalendarEvent()
                newEvent.id = UUID().uuidString
                newEvent.eventTitle = eventTitle
                newEvent.eventStartDate = eventStartDate
                newEvent.eventEndDate = eventEndDate
                newEvent.eventMemo = eventMemo
                newEvent.allDay = allDayToggle
                newEvent.colorData = colorData

                realm.add(newEvent)
            }
        }
        eventViewModel.fetchEvents()
        dismiss()
    }


    
    func encodeColorToData(_ color: Color) -> Data? {
        let uiColor = UIColor(color)
        return try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: true)
    }
    
    func decodeDataToColor(_ data: Data?) -> Color {
        guard let data = data, let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return .black
        }
        return Color(uiColor)
    }
    
    func stringToDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: dateString)
    }
    
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func createAlert(for alertType: AlertType) -> Alert {
        switch alertType {
        case .emptyTitle:
            return Alert(title: Text("Error"), message: Text("Title is empty."), dismissButton: .default(Text("OK")))
        case .invalidDateRange:
            return Alert(title: Text("Error"), message: Text("End time must be later than start time."), dismissButton: .default(Text("OK")))
        case .custom(let message):
            return Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func currentThemeDatePickerColorScheme() -> Bool {
        if themeManager.currentTheme == .dark || themeManager.currentTheme == .red || themeManager.currentTheme == .orange || themeManager.currentTheme == .green || themeManager.currentTheme == .blue {
            return true
        } else if themeManager.currentTheme == .system && colorScheme == .dark {
            return true
        } else {
            return false
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AppThemeManager())
}
