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
    private let monthRange = 120 // 月のスクロール範囲
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                headerView
                    .padding()
                
                if isPickerVisible {
                    // PickerView の表示
                    VStack(spacing: 0) {
                        HStack {
                            Picker("Year", selection: $selectedYear) {
                                let baseYear = Calendar.current.component(.year, from: Date())
                                let yearRange = (baseYear - monthRange / 12)...(baseYear + monthRange / 12)
                                ForEach(yearRange, id: \.self) { year in
                                    Text(String(year)).tag(year)
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
                }
                else {
                    // 通常のカレンダー表示
                    VStack(spacing: 0) {
                        // 曜日の表示
                        HStack {
                            ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekDay in
                                Text(weekDay)
                                    .font(.headline.weight(.thin))
                                    .frame(maxWidth: .infinity)
                                    .textCase(.uppercase)
                            }
                        }
                        .padding(.vertical)
                        
                        // カレンダーの表示
                        TabView(selection: $currentMonth) {
                            ForEach(-monthRange ... monthRange, id: \.self) { offset in
                                GeometryReader { tabGeometry in
                                    CalendarMonthView(
                                        offset: offset,
                                        selectedDates: $selectedDates,
                                        cellHeight: (tabGeometry.size.height / 6)
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
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(isWithinBounds(currentMonth - 1) && !isPickerVisible ? Color.primary : .gray)
            }
            .disabled(!isWithinBounds(currentMonth - 1) || isPickerVisible) // 範囲外またはピッカーが表示中の場合ボタン無効化
            Spacer()
            
            Text(getCurrentMonthYear())
                .font(.headline)
                .foregroundStyle(Color.primary)
                .onTapGesture {
                    isPickerVisible.toggle() // Picker をトグル表示
                }
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(isWithinBounds(currentMonth + 1) && !isPickerVisible ? Color.primary : .gray)
            }
            .disabled(!isWithinBounds(currentMonth + 1) || isPickerVisible) // 範囲外またはピッカーが表示中の場合ボタン無効化
        }
    }
    
    private func changeMonth(by offset: Int) {
        let newMonth = currentMonth + offset
        if isWithinBounds(newMonth) {
            withAnimation {
                currentMonth = newMonth
            }
        }
    }
    
    private func isWithinBounds(_ month: Int) -> Bool {
        (-monthRange...monthRange).contains(month)
    }
    
    private func getCurrentMonthYear() -> String {
        let currentDate = Calendar.current.date(byAdding: .month, value: currentMonth, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
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
    
    var body: some View {
        let days = getDaysForMonth()
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(days.indices, id: \.self) { index in
                DayView(date: days[index], selectedDates: $selectedDates, cellHeight: cellHeight)
                    .onTapGesture {
                        if let date = days[index] {
                            toggleDateSelection(date)
                        }
                    }
            }
        }
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
    
    var body: some View {
        VStack(spacing: 0) {
            if let date = date {
                GeometryReader { geometry in
                    ZStack {
                        // 日付テキスト
                        Text("\(calendar.component(.day, from: date))")
                            .font(.title3)
                            .foregroundStyle(isSelected(date) ? Color.white : (isToday(date) ? .accentColor : .primary))  // 現在の日付のテキスト色をaccentColorに変更
                            .frame(width: geometry.size.width, height: geometry.size.height) // Textを中央に配置
                            .multilineTextAlignment(.center)
                            .background(
                                Circle()
                                    .fill(isSelected(date) ? Color.blue.opacity(0.9) : Color.clear)  // 現在の日付の背景はなし
                                    .frame(maxWidth: geometry.size.width * 0.7)
                            )
                    }
                }
                
                Text("Event")
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: cellHeight)
    }
    
    private func isSelected(_ date: Date) -> Bool {
        selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}

struct StatefulPreviewWrapper<Content: View>: View {
    @State var currentMonth: Int
    @State var selectedDates: [Date]
    @State var isPickerVisible: Bool
    @State var selectedYear: Int
    @State var selectedMonth: Int
    
    let content: (Binding<Int>, Binding<[Date]>, Binding<Bool>, Binding<Int>, Binding<Int>) -> Content
    
    var body: some View {
        content($currentMonth, $selectedDates, $isPickerVisible, $selectedYear, $selectedMonth)
    }
}

#Preview {
    VStack {
        // プレビュー用の親ビューで状態を管理
        StatefulPreviewWrapper(currentMonth: 0, selectedDates: [], isPickerVisible: false, selectedYear: Calendar.current.component(.year, from: Date()), selectedMonth: Calendar.current.component(.month, from: Date())) { currentMonth, selectedDates, isPickerVisible, selectedYear, selectedMonth in
            CalendarView(currentMonth: currentMonth, selectedDates: selectedDates, isPickerVisible: isPickerVisible, selectedYear: selectedYear, selectedMonth: selectedMonth)
        }
        
        // もう一つの状態のプレビュー
        StatefulPreviewWrapper(currentMonth: 0, selectedDates: [Date()], isPickerVisible: false, selectedYear: Calendar.current.component(.year, from: Date()), selectedMonth: Calendar.current.component(.month, from: Date())) { currentMonth, selectedDates, isPickerVisible, selectedYear, selectedMonth in
            CalendarView(currentMonth: currentMonth, selectedDates: selectedDates, isPickerVisible: isPickerVisible, selectedYear: selectedYear, selectedMonth: selectedMonth)
        }
    }
}
