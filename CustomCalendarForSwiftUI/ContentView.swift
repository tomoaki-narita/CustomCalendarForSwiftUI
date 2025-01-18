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
    @State private var isPickerVisible: Bool = false  // Picker の表示状態
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @ObservedResults(EventDate.self, sortDescriptor: SortDescriptor(keyPath: "sortOrder", ascending: true)) var events
    @State private var selectedEvent: EventDate?
    @State private var showEventPickerView: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    CalendarView(
                        currentMonth: $currentMonth,
                        selectedDates: $selectedDates,
                        isPickerVisible: $isPickerVisible,
                        selectedYear: $selectedYear,
                        selectedMonth: $selectedMonth
                    )
//                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .blur(radius: showEventPickerView ? 2.5 : 0)
                    .allowsHitTesting(!showEventPickerView)
                    
                        HStack {
                            Spacer()
                            Button(action:{
                                resetCalendar()
                            }) {
                                
                                Image(systemName: "arrow.trianglehead.2.clockwise")
                                    .foregroundStyle(Color.primary)
                                    .font(.title3)
                                    .padding()
                                    .shadow(radius: 10)
                            }
                            .disabled(isPickerVisible)
                            Spacer()
                            Button(action: {
                                withAnimation(.snappy(duration: 0.5)) {
                                    showEventPickerView.toggle()
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.primary)
                                    .font(.title2)
                                    .padding()
                                    .shadow(radius: 10)
                            }
                            Spacer()
                            NavigationLink(destination: EditView()) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(Color.primary)
                                    .font(.title3)
                                    .padding()
                                    .shadow(radius: 10)
                            }
                            Spacer()
                        }
                        .allowsHitTesting(!showEventPickerView) //opacityが0になるとタップできなくなるため不要だが一応残す
                        .opacity(showEventPickerView ? 0 : 1)
                    
                }
                .padding()

            }
        }
        .overlay {
            // EventPickerViewが表示されるとき
            if showEventPickerView {
                EventPickerView(events: Array(events)) {
                    withAnimation(.snappy(duration: 1.5)) {
                        showEventPickerView = false // バツボタンでEventPickerViewを非表示にする
                    }
                }
                .transition(.move(edge: .bottom)) // 下からスライドするアニメーション
            }
        }
        
    }
    
    private func resetCalendar() {
        currentMonth = 0 // 現在の月に戻す
        selectedDates.removeAll() // 選択を解除
        isPickerVisible = false // ピッカーを閉じる
        selectedEvent = nil
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
}

#Preview {
    ContentView()
}
