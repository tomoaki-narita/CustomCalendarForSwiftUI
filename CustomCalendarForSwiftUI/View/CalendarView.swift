//
//  CalendarView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2024/12/27.
//

import SwiftUI

struct CalendarView: View {
    @Binding var currentMonth: Int
    @Binding var selectedDates: [Date]
    @Binding var isPickerVisible: Bool
    @Binding var selectedYear: Int  // Bindingで年を受け取る
    @Binding var selectedMonth: Int // Bindingで月を受け取る
    private let calendar = Calendar.current
    let weekSymbols = Calendar.current.shortWeekdaySymbols
    let todayWeekday = Calendar.current.component(.weekday, from: Date()) - 1 // 日曜始まりなので -1 で調整
    private let monthRange = 120 // 月のスクロール範囲
    @State private var isLeftButton: Bool = false
    @State private var isRightButton: Bool = false
    var events: [CalendarEvent] // イベントリストを受け取る
    var onLongTap: (Date) -> Void // 追加: ロングタップ時のクロージャ
    @ObservedObject var viewModel: HolidayViewModel
    @EnvironmentObject var themeManager: AppThemeManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal)
                if isPickerVisible {
                    // PickerView の表示
                    VStack(spacing: 0) {
                        HStack {
                            Picker("Year", selection: $selectedYear) {
                                let baseYear = Calendar.current.component(.year, from: Date())
                                let yearRange = (baseYear - monthRange / 12)...(baseYear + monthRange / 12)
                                ForEach(yearRange, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: geometry.size.width * 0.4)
                            .onChange(of: selectedYear) {
                                let allowedMonths = allowedMonthsForSelectedYear()
                                if !allowedMonths.contains(selectedMonth) {
                                    selectedMonth = allowedMonths.first ?? 1 // 初期値を最初の月に設定
                                }
                                updateCurrentMonth()
                            }
                            
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(allowedMonthsForSelectedYear(), id: \.self) { month in
                                    Text(calendar.monthSymbols[month - 1]).tag(month)
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: geometry.size.width * 0.4)
                            .onChange(of: selectedMonth) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    updateCurrentMonth() // 月が変更されたら更新
                                }
                            }
                        }
                        .frame(height: geometry.size.height * 0.8)
                        .cornerRadius(16)
                    }
                } else {
                    // 通常のカレンダー表示
                    VStack(spacing: 0) {
                        // 曜日の表示
                        HStack {
                            ForEach(weekSymbols.indices, id: \.self) { index in
                                Text(weekSymbols[index].prefix(index == todayWeekday ? 3 : 1))
                                    .font(.system(.subheadline))
                                    .frame(maxWidth: .infinity)
                                    .textCase(.uppercase)
                                    .foregroundStyle(index == todayWeekday ? Color.accentColor : Color(themeManager.currentTheme.tertiaryColor))
                            }
                        }
                        .padding(.bottom, 20)
                        // カレンダーの表示
                        TabView(selection: $currentMonth) {
                            ForEach(-monthRange ... monthRange, id: \.self) { offset in
                                GeometryReader { tabGeometry in
                                    CalendarMonthView(
                                        offset: offset,
                                        selectedDates: $selectedDates,
                                        cellHeight: (tabGeometry.size.height / 6.5),
                                        events: events,
                                        onLongTap: onLongTap,
                                        viewModel: viewModel
                                    )
                                    .tag(offset)
                                }
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    }
                }
            }
        }
        .animation(.default, value: isPickerVisible)
//        .fontDesign(.rounded)
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack(alignment: .leading) {
                Text(getCurrentMonthBackground())
                    .font(.system(size: 120, weight: .heavy))
                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.2))
                    .baselineOffset(5)
                    .offset(x: 10)
                
                HStack(alignment: .center) {
                    Text(getCurrentMonth())
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(1))
                    
                    Text(getCurrentYear())
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(1))
                }
            }
            .onTapGesture {
                isPickerVisible.toggle()
            }
            
            Spacer()
            
            Button(action: {
                changeMonth(by: -1)
                isLeftButton.toggle()
            }){
                Image(systemName: "chevron.left")
                    .foregroundStyle(isWithinBounds(currentMonth - 1) && !isPickerVisible ? Color(themeManager.currentTheme.tertiaryColor) : .clear)
            }
            .symbolEffect(.bounce.down.wholeSymbol, value: isLeftButton)
            .disabled(!isWithinBounds(currentMonth - 1) || isPickerVisible) // 範囲外またはピッカーが表示中の場合ボタン無効化
            
            Spacer()
                .frame(maxWidth: 15)
            
            Button(action: {
                changeMonth(by: 1)
                isRightButton.toggle()
            }){
                Image(systemName: "chevron.right")
                    .foregroundStyle(isWithinBounds(currentMonth + 1) && !isPickerVisible ? Color(themeManager.currentTheme.tertiaryColor) : .clear)
            }
            .symbolEffect(.bounce.down.wholeSymbol, value: isRightButton)
            .disabled(!isWithinBounds(currentMonth + 1) || isPickerVisible) // 範囲外またはピッカーが表示中の場合ボタン無効化
        }
    }
    
    private func changeMonth(by offset: Int) {
        let newMonth = currentMonth + offset
        if isWithinBounds(newMonth) {
            withAnimation(.snappy) {
                currentMonth = newMonth
            }
        }
    }
    
    private func isWithinBounds(_ month: Int) -> Bool {
        (-monthRange...monthRange).contains(month)
    }
    
    private func getCurrentYear() -> String {
        let currentDate = Calendar.current.date(byAdding: .month, value: currentMonth, to: Date()) ?? Date()
        let formatter = DateFormatter()
        let currentLanguage = Locale.current.language.languageCode?.identifier
        if currentLanguage == "ja" {
            formatter.dateFormat = "yyyy"
        } else {
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: currentDate)
    }
    
    private func getCurrentMonth() -> String {
        let currentDate = Calendar.current.date(byAdding: .month, value: currentMonth, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
//        let currentLanguage = Locale.current.language.languageCode?.identifier
//        if currentLanguage == "ja" {
//            formatter.dateFormat = "MM"
//        } else {
            formatter.dateFormat = "MMMM"
//        }
        return formatter.string(from: currentDate)
    }
    
    private func getCurrentMonthBackground() -> String {
        let currentDate = Calendar.current.date(byAdding: .month, value: currentMonth, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
                    formatter.dateFormat = "M"
        return formatter.string(from: currentDate)
    }
    
    private func updateCurrentMonth() {
        let baseDate = Date()
        let baseYear = calendar.component(.year, from: baseDate)
        let baseMonth = calendar.component(.month, from: baseDate)
        currentMonth = (selectedYear - baseYear) * 12 + (selectedMonth - baseMonth)
    }
    
    // 動的に月のリストを取得する関数
    private func allowedMonthsForSelectedYear() -> [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        let maxYear = currentYear + monthRange / 12
        let minYear = currentYear - monthRange / 12
        
        if selectedYear == minYear {
            // 最小の年の場合、1月から現在の月までが選択可能
            return Array(currentMonth...12)
        } else if selectedYear == maxYear {
            // 最大の年の場合、1月から現在の月までが選択可能
            return Array(1...currentMonth)
        } else {
            // その他の年は全ての月が選択可能
            return Array(1...12)
        }
    }
}

struct CalendarMonthView: View {
    let offset: Int
    @Binding var selectedDates: [Date]
    let cellHeight: CGFloat
    private let calendar = Calendar.current
    var events: [CalendarEvent] // イベントリストを受け取る
    var onLongTap: (Date) -> Void // 追加: ロングタップ時のクロージャ
    @ObservedObject var viewModel: HolidayViewModel
    @EnvironmentObject var themeManager: AppThemeManager
    
    var body: some View {
        let days = getDaysForMonth()
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(days.indices, id: \.self) { index in
                DayView(
                    date: days[index],
                    selectedDates: $selectedDates,
                    cellHeight: cellHeight,
                    events: events,
                    onLongTap: onLongTap, viewModel: viewModel
                )
                .onTapGesture {
                    if let date = days[index] {
                        toggleDateSelection(date)
                    }
                }
                
                
            }
        }
//        .fontDesign(.rounded)
    }
    
    private func getDaysForMonth() -> [Date?] {
        guard let firstOfMonth = calendar.date(byAdding: .month, value: offset, to: Date()) else { return [] }
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: firstOfMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        let previousMonthDays: [Date?] = (1 - firstWeekday..<1).map { _ in nil }
        let currentMonthDays = (1..<range.count + 1).map { day -> Date? in
            return calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
        let nextMonthDays: [Date?] = (currentMonthDays.count + previousMonthDays.count..<42).map { _ in nil }
        
        return previousMonthDays + currentMonthDays + nextMonthDays
    }
    
    private func toggleDateSelection(_ date: Date) {
        if let index = selectedDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            selectedDates.remove(at: index)
        } else {
            selectedDates.append(date)
        }
        print("Selected Dates:", selectedDates.map { calendar.dateComponents([.year, .month, .day], from: $0) })
    }
}

struct DayView: View {
    
    let date: Date?
    @Binding var selectedDates: [Date]
    let cellHeight: CGFloat
    private let calendar = Calendar.current
    let events: [CalendarEvent] // イベントデータを追加
    var onLongTap: (Date) -> Void // 追加: ロングタップ時のクロージャ
    private let eventTitleHeight: CGFloat = 20
    @ObservedObject var viewModel: HolidayViewModel
    @EnvironmentObject var themeManager: AppThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            if let date = date {
                GeometryReader { geometry in
                    ZStack {
                        // 日付テキスト
                        Text("\(calendar.component(.day, from: date))")
                            .font(.title3)
                            .foregroundStyle(getDateColor(for: date))
                        // 現在の日付のテキスト色をaccentColorに変更
                            .frame(width: geometry.size.width, height: geometry.size.height) // Textを中央に配置
                            .multilineTextAlignment(.center)
                            .background(
                                Circle()
                                    .fill(isSelected(date) ? Color(themeManager.currentTheme.tertiaryColor).opacity(0.25) : Color.clear)  // 現在の日付の背景はなし
                                    .frame(maxWidth: geometry.size.width * 0.7)
                            )
                            
                    }
                    
                }
                
                // イベントタイトルを取得して表示
                if let eventDataList = getUpcomingEvents(for: date), !eventDataList.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(eventDataList, id: \.self) { eventData in
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 10, style: .circular)
                                    .frame(width: 3, height: 10)
                                    .foregroundStyle(eventData.color)
                                    .padding(.leading, 3)
                                
                                Text(eventData.title)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 2)
                                    .font(.caption2)
                                    .foregroundStyle(eventData.isPast ? Color(themeManager.currentTheme.tertiaryColor).opacity(0.5) : Color(themeManager.currentTheme.tertiaryColor))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                            }
                            .background {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(eventData.color.opacity(0.2))
                                    .frame(height: 15)
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    .frame(height: eventTitleHeight, alignment: .top)
                } else {
                    Text("")
                        .font(.footnote)
                        .foregroundStyle(Color.clear)
                        .multilineTextAlignment(.center)
                        .frame(height: eventTitleHeight)
                }
            }
        }
        .frame(height: cellHeight)
        .onLongPressGesture {
            if let date = date {
                onLongTap(date) // ロングタップされた日付を渡す
            }
        }
//        .fontDesign(.rounded)
    }
    
    private func getDateColor(for date: Date) -> Color {
        if isHoliday(date) { // 祝日なら赤色
            return Color("HolidayColor")
        } else if isToday(date) { // 今日
            return .accentColor
        } else if isSelected(date) { // 選択中
            return Color(themeManager.currentTheme.tertiaryColor)
        } else {
            return Color(themeManager.currentTheme.tertiaryColor) // デフォルト色
        }
    }
    
    // 該当の日付が祝日かどうかを判定
    private func isHoliday(_ date: Date) -> Bool {
        viewModel.holidays.contains { holiday in
            guard let holidayDate = holiday.dateFormatted else { return false }
            return calendar.isDate(holidayDate, inSameDayAs: date)
        }
    }
    
    private func getUpcomingEvents(for date: Date) -> [EventData]? {
        let eventsForDay = events
            .filter { calendar.isDate($0.eventStartDate, inSameDayAs: date) }
            .sorted { $0.eventStartDate < $1.eventStartDate }
        let now = Date()
        let upcomingEvents = eventsForDay.filter { $0.eventStartDate > now }
        
        if !upcomingEvents.isEmpty {
            return upcomingEvents.prefix(2).map {
                EventData(
                    title: $0.eventTitle,
                    color: decodeDataToColor($0.colorData),
                    isPast: false,
                    startDate: $0.eventStartDate // Date 型でそのまま使う
                )
            }
        }
        
        // すべて過去のイベントなら最も遅いものを1つだけ取得
        if let lastEvent = eventsForDay.last {
            return [EventData(
                title: lastEvent.eventTitle,
                color: decodeDataToColor(lastEvent.colorData),
                isPast: true,
                startDate: lastEvent.eventStartDate  // Date 型でそのまま使う
            )]
        }
        
        return nil
    }

    func decodeDataToColor(_ data: Data?) -> Color {
        guard let data = data,
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return .gray // デコード失敗時はデフォルトで灰色
        }
        return Color(uiColor) // UIColorからColorに変換して返す
    }

    
    private func isSelected(_ date: Date) -> Bool {
        selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}

struct EventData: Identifiable, Hashable {
    let id: UUID // 各イベントのユニークID
    let title: String
    let color: Color
    let isPast: Bool
    let startDate: Date  // Date 型で保持

    // イベントのユニークな識別子として `id` を使用
    init(title: String, color: Color, isPast: Bool, startDate: Date) {
        self.id = UUID() // UUIDで一意の識別子を作成
        self.title = title
        self.color = color
        self.isPast = isPast
        self.startDate = startDate
    }

    // Hashable に準拠
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(startDate)
        hasher.combine(title)
    }

    static func == (lhs: EventData, rhs: EventData) -> Bool {
        return lhs.id == rhs.id
    }
}

#Preview {
    ContentView()
        .environmentObject(AppThemeManager())
}
