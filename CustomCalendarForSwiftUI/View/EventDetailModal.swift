//
//  EventDetailModal.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/01/24.
//
import SwiftUI

struct EventDetailModal: View {
    let date: Date
    let events: [CalendarEvent]
    
    private let calendar = Calendar.current
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // ヘッダー
            Text("Event Details for \(formattedDate(date))")
                .font(.title2)
                .padding(.top)
            
            // イベント情報をリスト表示
            let eventsForDay = events.filter { calendar.isDate($0.eventStartDate, inSameDayAs: date) }
            if eventsForDay.isEmpty {
                Text("No events for this date.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(eventsForDay, id: \.id) { event in
                    Text(event.eventTitle)
                        .font(.body)
                        .padding(.horizontal)
                        .foregroundStyle(Color(decodeDataToColor(event.colorData)))
                }
            }
            
            // 閉じるボタン
            Button(action: {
                dismiss()
            }) {
                Text("Close")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom)
        }
        .frame(width: 300, height: 400)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    func decodeDataToColor(_ data: Data?) -> Color {
        guard let data = data, let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return .black
        }
        return Color(uiColor)
    }
}
