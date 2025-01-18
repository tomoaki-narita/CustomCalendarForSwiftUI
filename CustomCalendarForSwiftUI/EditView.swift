//
//  EditView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2024/12/27.
//

import SwiftUI
import RealmSwift

struct EditView: View {
    @State var isEditViewVisible: Bool = false
    @State var editingEvent: EventDate? = nil
    @ObservedResults(EventDate.self, sortDescriptor: SortDescriptor(keyPath: "sortOrder", ascending: true)) var events
    let plusImage: Image = Image(systemName: "plus")
    let starImage: Image = Image(systemName: "star.fill").symbolRenderingMode(.multicolor)
    let clockImage: Image = Image(systemName: "clock").symbolRenderingMode(.multicolor)
    let memoImage: Image = Image(systemName: "note.text").symbolRenderingMode(.multicolor)
    

    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.purple.ignoresSafeArea()
                List {
                    Section {
                        Button {
                            isEditViewVisible = true
                            editingEvent = nil // 新規作成モード
                        } label: {
                            HStack {
                                Spacer()
                                Text("Create new event")
                                plusImage.font(.footnote)
                                Spacer()
                            }
                        }
                        .sheet(isPresented: $isEditViewVisible) {
                            CreateNewEventView(
                                editingEvent: $editingEvent,
                                selectedColor: .primary
                            )
                        }
                    }
                    
                    Section {
                        ForEach(events, id: \.id) { event in
                            HStack {
                                Circle()
                                    .frame(width: 10)
                                    .foregroundStyle(decodeDataToColor(event.colorData))
                                Text(event.eventTitle)
//                                    .foregroundStyle(decodeDataToColor(event.colorData))
                  
                                if let memo = event.eventMemo, !memo.isEmpty {
                                    memoImage.font(.footnote).opacity(0.25)
                                }
                                Spacer()
                                HStack(spacing: 3) {
                                    if event.allDay {
                                        starImage.font(.footnote).opacity(0.25)
                                    }
                                    Text("\(formatDate(event.eventStartDate))")
                                        .font(.footnote)
                                    Text("-")
                                    Text("\(formatDate(event.eventEndDate))")
                                        .font(.footnote)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingEvent = event // 編集モードに設定
                                    isEditViewVisible = true
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                }
                                
                            }
                            
                            
                        }
                        .onDelete(perform: { index in
                            $events.remove(atOffsets: index)
                        })
                        .onMove(perform: moveEvent)
                    }
                    .frame(height:40)
//                    .listRowBackground(
//                        RoundedRectangle(cornerRadius: 15)
//                            .fill(Color.white.opacity(0.5))
//                            .padding(.vertical, 3)
//                    )
                    
                }
                
//                .scrollContentBackground(.hidden)

                .toolbar {
                    EditButton()
                }
            }
        }
    }
    
    func moveEvent(from source: IndexSet, to destination: Int) {
        _ = source.map { events[$0] }
        var updatedEvents = Array(events)
        updatedEvents.move(fromOffsets: source, toOffset: destination)
        
        do {
            let realm = try Realm()
            try realm.write {
                for (index, event) in updatedEvents.enumerated() {
                    if let objectToUpdate = realm.object(ofType: EventDate.self, forPrimaryKey: event.id) {
                        objectToUpdate.sortOrder = index
                    }
                }
            }
        } catch {
            print("Error updating event order in Realm: \(error.localizedDescription)")
        }
    }

    
//    func fetchEvents() {
//        do {
//            let realm = try Realm()
//            let savedEvents = realm.objects(EventDate.self).sorted(byKeyPath: "sortOrder", ascending: true)
//            events = Array(savedEvents)
//        } catch {
//            print("Error fetching events from Realm: \(error.localizedDescription)")
//        }
//    }
    
    func decodeDataToColor(_ data: Data?) -> Color {
        guard let data = data, let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return .black
        }
        return Color(uiColor)
    }
    
    func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm"
        return outputFormatter.string(from: date)
    }
}

struct CreateNewEventView: View {
//    @Binding var events: [EventDate]
    @ObservedResults(EventDate.self, sortDescriptor: SortDescriptor(keyPath: "sortOrder", ascending: true)) var events

    @Binding var editingEvent: EventDate?
    @State var eventTitle: String = ""
    @State var eventMemo: String = ""
    @State var eventStartDate: Date = Date()
    @State var eventEndDate: Date = Date()
    @State var allDayToggle: Bool = false
    @State var selectedColor: Color
    @State private var activeAlert: AlertType? = nil
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusdFieldForEventTitleTextField: Field?
    @FocusState private var focusdFieldForEventMemoTextField: Field?
    let starImage: Image = Image(systemName: "star.fill").symbolRenderingMode(.multicolor)
    let textImage: Image = Image(systemName: "t.square").symbolRenderingMode(.multicolor)
    let clockImage: Image = Image(systemName: "clock").symbolRenderingMode(.multicolor)
    let memoImage: Image = Image(systemName: "note.text").symbolRenderingMode(.multicolor)
    let colorImage: Image = Image(systemName: "swatchpalette").symbolRenderingMode(.multicolor)
    
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
                List {
                    Section {
                        HStack {
                            textImage.font(.footnote)
                            Text("Event title")
                            Spacer()
                            TextField("Enter event title", text: $eventTitle)
                                .focused($focusdFieldForEventTitleTextField, equals: Field.eventName)
                                .multilineTextAlignment(TextAlignment.trailing)
                            eventTitle != "" ?
                            Button {
                                eventTitle = ""
                            } label: {
                                Image(systemName: "delete.left")
                                    .foregroundStyle(Color.gray)
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 2)
                            : nil
                        }
                        .frame(minHeight: 40)
                        
                        HStack {
                            clockImage.font(.footnote)
                            DatePicker("Start", selection: $eventStartDate, displayedComponents: [.hourAndMinute])
                                .environment(\.locale, .init(identifier: "ja"))
                                .padding(.vertical, 1)
                                .frame(minHeight: 40)
                        }
                        
                        HStack {
                            clockImage.font(.footnote)
                            DatePicker("End", selection: $eventEndDate, displayedComponents: [.hourAndMinute])
                                .environment(\.locale, .init(identifier: "ja"))
                                .padding(.vertical, 1)
                                .frame(minHeight: 40)
                        }
                        
                        Toggle(isOn: $allDayToggle) {
                            HStack {
                                starImage.font(.footnote)
                                Text("All day")
                            }
                            .frame(minHeight: 40)
                        }
                        
                        HStack {
                            memoImage.font(.footnote)
                            Text("Memo")
                            Spacer()
                            TextField("Enter event memo", text: $eventMemo)
                                .focused($focusdFieldForEventMemoTextField, equals: Field.eventMemo)
                                .multilineTextAlignment(TextAlignment.trailing)
                            eventMemo != "" ?
                            Button {
                                eventMemo = ""
                            } label: {
                                Image(systemName: "delete.left")
                                    .foregroundStyle(Color.gray)
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 2)
                            : nil
                        }
                        .frame(minHeight: 40)
                        
                        HStack {
                            colorImage.font(.footnote)
                            Text("Color")
                            Spacer()
                            ColorPicker("Select color", selection: $selectedColor, supportsOpacity: true)
                                .labelsHidden()
                        }
                        .frame(minHeight: 40)
                    }

                    
                    Section {
                        HStack {
                            Spacer()
                            Button(editingEvent == nil ? "Add" : "Save") {
                                handleSaveButtonTapped()
                            }
                            Spacer()
                        }
                    }
//                    .listRowBackground(
//                        RoundedRectangle(cornerRadius: 20)
//                            .fill(Color.clear)
//                            .padding(.vertical, 5)
//                    )
                }
                .navigationTitle(editingEvent == nil ? "Create Event" : "Edit Event")
                .toolbar {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.primary)
                    }
                }
                .onAppear {
                    if let editingEvent = editingEvent {
                        eventTitle = editingEvent.eventTitle
                        eventMemo = editingEvent.eventMemo ?? ""
                        eventStartDate = stringToDate(editingEvent.eventStartDate) ?? Date()
                        eventEndDate = stringToDate(editingEvent.eventEndDate) ?? Date()
                        allDayToggle = editingEvent.allDay
                        selectedColor = decodeDataToColor(editingEvent.colorData)
                    }
                }
                .alert(item: $activeAlert, content: createAlert)
            }
        }
    }
    
    func handleSaveButtonTapped() {
        // タイトルが空かどうかを確認
        if eventTitle.isEmpty {
            activeAlert = .emptyTitle // タイトルが空の場合のアラート
        }
        // 日付の範囲が無効かどうかを確認
        else if eventEndDate <= eventStartDate {
            activeAlert = .invalidDateRange // 日付範囲が不正の場合のアラート
        }
        else {
            let startDateStr = dateToString(eventStartDate)
            let endDateStr = dateToString(eventEndDate)
            let colorData = encodeColorToData(selectedColor)
            
            if let editingEvent = editingEvent {
                // 編集の場合
                if let eventToUpdate = events.first(where: { $0.id == editingEvent.id }) {
                    do {
                        let realm = try Realm()
                        try realm.write {
                            if let objectToUpdate = realm.object(ofType: EventDate.self, forPrimaryKey: eventToUpdate.id) {
                                objectToUpdate.eventTitle = eventTitle
                                objectToUpdate.eventMemo = eventMemo
                                objectToUpdate.eventStartDate = startDateStr
                                objectToUpdate.eventEndDate = endDateStr
                                objectToUpdate.allDay = allDayToggle
                                objectToUpdate.colorData = colorData
                            }
                        }
                    } catch {
                        print("Error updating event: \(error.localizedDescription)")
                    }
                }
            } else {
                // 新規作成の場合
                let newEvent = EventDate(
                    eventTitle: eventTitle,
                    eventStartDate: startDateStr,
                    eventEndDate: endDateStr,
                    eventMemo: eventMemo.isEmpty ? nil : eventMemo, // memoが空の場合はnil
                    allDay: allDayToggle,
                    id: UUID().uuidString, // 新規IDをUUIDで生成
                    sortOrder: events.count, // 追加されるイベントの順番を設定
                    colorData: colorData
                )

                do {
                    let realm = try Realm()
                    try realm.write {
                        realm.add(newEvent)
                    }
                } catch {
                    print("Error saving new event: \(error.localizedDescription)")
                }
            }

            dismiss()
        }
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
        formatter.dateFormat = "HH:mm:ss"
        return formatter.date(from: dateString)
    }
    
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func createAlert(for alertType: AlertType) -> Alert {
        switch alertType {
        case .emptyTitle:
            return Alert(title: Text("Error"), message: Text("Event title cannot be empty."), dismissButton: .default(Text("OK")))
        case .invalidDateRange:
            return Alert(title: Text("Error"), message: Text("End time must be later than start time."), dismissButton: .default(Text("OK")))
        case .custom(let message):
            return Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
        }
    }
}


#Preview {
    EditView()
}
