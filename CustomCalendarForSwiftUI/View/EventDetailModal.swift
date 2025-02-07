//
//  EventDetailModal.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/01/24.
//
import SwiftUI
import RealmSwift
import Combine

struct EventDetailModal: View {
    let date: Date
    private let calendar = Calendar.current
    let memoImage: Image = Image(systemName: "note.text")
    @ObservedObject var eventViewModel: EventViewModel
    @ObservedObject var viewModel: HolidayViewModel
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isDeleteAlertPresented = false
    @State private var eventToEdit: CalendarEvent? = nil
    @State private var expandedEventIDs: Set<String> = []
    @State private var editingEventID: String? = nil
    @State private var tempMemo: String = ""
    @State private var isMemoSavedSuccess: Bool = true
    @StateObject private var keyboardResponder = KeyboardResponder()
    
    @State var isEditViewVisible: Bool = false
    @State var editingEvent: CalendarEvent? = nil
    
    
    let plusImage: Image = Image(systemName: "plus")
    
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(themeManager.currentTheme.primaryColor).ignoresSafeArea()
                VStack {
                    List {
                        let holidayName = getHolidayName(for: date)
                        Section {
                            HStack {
                                Text(formattedDate(date))
                                    .font(.title2).bold()
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                Spacer()
                                Text(holidayName ?? "")
                                    .font(.footnote)
                                    .foregroundStyle(.holiday)
                            }
                            .listRowBackground(Color.clear)
                        }
                        
                        let eventsForDay = eventViewModel.events.filter { calendar.isDate($0.eventStartDate, inSameDayAs: date) }
                            .sorted { $0.eventStartDate < $1.eventStartDate } // ここで開始時刻順にソート
                        if eventsForDay.isEmpty {
                            Section {
                                Text("None")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                            } header: {
                                Text("No events")
                                    .font(.headline)
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                            }
                            .listRowBackground(Color.clear)
                        } else {
                            
                            
                            
                            ForEach(eventsForDay, id: \.id) { event in
                                let isExpanded = expandedEventIDs.contains(event.id)
                                Section {
                                    DisclosureGroup(
                                        isExpanded: Binding(
                                            get: { isExpanded },
                                            set: { newValue in
                                                if newValue {
                                                    expandedEventIDs.insert(event.id)  // 開く
                                                } else {
                                                    expandedEventIDs.remove(event.id)  // 閉じる
                                                }
                                            }
                                        )
                                    ){
                                        HStack(alignment: .top) {
                                            memoImage.font(.footnote)
                                                .padding(.top, 4)
                                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                            
                                            ZStack(alignment: .leading) {
                                                if (event.eventMemo ?? "").isEmpty && isMemoSavedSuccess {
                                                    Text("No memo available.")
                                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                                                }
                                                
                                                TextField("", text: Binding(
                                                    get: { event.eventMemo ?? "" },
                                                    set: { newValue in
                                                        if newValue != event.eventMemo {
                                                            isMemoSavedSuccess = false
                                                        }
                                                        tempMemo = newValue
                                                        editingEventID = event.id
                                                        withAnimation {
                                                            expandedEventIDs = [event.id]
                                                        }
                                                    }
                                                ), axis: .vertical)
                                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                            }
                                        }
                                        .frame(minHeight: 40)
                                        
                                        // 各イベントごとのsaveボタンを表示
                                        if isExpanded && keyboardResponder.isKeyboardVisible && editingEventID == event.id {
                                            HStack {
                                                Spacer()
                                                Button {
                                                    saveMemoToRealm(eventID: event.id, newMemo: tempMemo)
                                                    editingEventID = nil  // 編集終了
                                                    hideKeyboard()
                                                } label: {
                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(isMemoSavedSuccess ? Color.accentColor : Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .listRowSeparator(.hidden)
                                        }
                                    } label: {
                                        HStack {
                                            RoundedRectangle(cornerRadius: 10, style: .circular)
                                                .frame(width: 5, height: 25)
                                                .foregroundStyle(Color(decodeDataToColor(event.colorData)))
                                            
                                            Text(event.eventTitle)
                                                .font(.body)
                                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                            
                                            if let memo = event.eventMemo, !memo.isEmpty {
                                                memoImage.font(.footnote)
                                                    .foregroundColor(Color(themeManager.currentTheme.tertiaryColor))
                                                    .font(.caption)
                                            }
                                            
                                            Spacer()
                                            
                                            if event.allDay {
                                                Text("All day")
                                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                                            }
                                        }
                                        .onTapGesture {
                                            // 開閉のトグル
                                            withAnimation {
                                                if isExpanded {
                                                    _ = expandedEventIDs.remove(event.id)
                                                } else {
                                                    _ = expandedEventIDs.insert(event.id)
                                                }
                                                editingEventID = nil
                                            }
                                        }
                                    }
                                    .tint(Color(themeManager.currentTheme.tertiaryColor))
                                } header: {
                                    HStack(alignment: .bottom) {
                                        Text("\(dateToString(event.eventStartDate)) - \(dateToString(event.eventEndDate))")
                                            .font(.headline)
                                            .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                        
                                        Spacer()
                                        Button(action: {
                                            eventToEdit = event
                                            isDeleteAlertPresented = true
                                        }){
                                            Image(systemName: "trash")
                                                .foregroundStyle(.red)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingEvent = event // 編集モードに設定
                                        isEditViewVisible = true
                                    } label: {
                                        Image(systemName: "square.and.pencil")
                                    }
                                    .tint(.blue)
                                }
                                .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                            }
                            
                            
                            
                            
                        }
                        
                        Section {
                            Button {
                                    isEditViewVisible = true
                                    editingEvent = nil // 新規作成モード
                            } label: {
                                Spacer()
                                
                                Text("\(plusImage) New event")
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                    .font(.footnote)
                                    .padding(10)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(themeManager.currentTheme.tertiaryColor), lineWidth: 0.8)
                                    )
                                
                                Spacer()
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $isEditViewVisible) {
                                CreateNewEventViewForCalendarEvent(
                                    editingEvent: $editingEvent,
                                    selectedColor: .primary,
                                    selectedDate: date
                                )
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                    .animation(.default, value: isDeleteAlertPresented)
                    .headerProminence(.increased)
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .tint(Color(themeManager.currentTheme.tertiaryColor))
                            .fontWeight(.bold)
                            .font(.caption2)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color(themeManager.currentTheme.tertiaryColor).opacity(0.1))
                                    .frame(width: 28)
                            )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Details")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(themeManager.currentTheme.tertiaryColor)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(themeManager.currentTheme.primaryColor), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            
            .alert(isPresented: $isDeleteAlertPresented) {
                Alert(
                    title: Text("\(eventToEdit?.eventTitle ?? "Confirm deletion")"),
                    message: Text("Do you want to delete the event?"),
                    primaryButton: .cancel(Text("Cancel")){},
                    secondaryButton: .destructive(Text("Delete")) {
                        if let event = eventToEdit, !event.isInvalidated {
                            eventViewModel.deleteEvent(event)
                        } else {
                            print("This event has already been deleted.")
                        }
                    }
                )
            }
        }
    }
    
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let currentLanguage = Locale.current.language.languageCode?.identifier
        if currentLanguage == "ja" {
            formatter.dateFormat = "yyyy MM-d E "
        } else {
            formatter.dateFormat = "E MMM dd, yyyy"
        }
        return formatter.string(from: date)
    }
    
    func decodeDataToColor(_ data: Data?) -> Color {
        guard let data = data, let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return .black
        }
        return Color(uiColor)
    }
    
    private func getHolidayName(for date: Date) -> String? {
        guard let holiday = viewModel.holidays.first(where: { holiday in
            guard let holidayDate = holiday.dateFormatted else { return false }
            return Calendar.current.isDate(holidayDate, inSameDayAs: date)
        }) else {
            return nil
        }
        return holiday.name
    }
    
    func saveMemoToRealm(eventID: String, newMemo: String) {
        do {
            let realm = try Realm()
            if let event = realm.object(ofType: CalendarEvent.self, forPrimaryKey: eventID) {
                try realm.write {
                    event.eventMemo = newMemo
                }
                isMemoSavedSuccess = true
                print("Memo saved: \(newMemo)")  // ← 保存確認
            } else {
                print("Event not found in Realm")
            }
        } catch {
            print("Failed to save memo: \(error.localizedDescription)")
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

final class KeyboardResponder: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification))
            .sink { notification in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isKeyboardVisible = (notification.name == UIResponder.keyboardWillShowNotification)
                }
            }
    }
}


#Preview {
    ContentView()
        .environmentObject(AppThemeManager())
}
