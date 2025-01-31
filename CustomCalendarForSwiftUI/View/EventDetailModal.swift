//
//  EventDetailModal.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/01/24.
//
import SwiftUI

struct EventDetailModal: View {
    let date: Date
    private let calendar = Calendar.current
    let memoImage: Image = Image(systemName: "note.text").symbolRenderingMode(.multicolor)
    @ObservedObject var eventViewModel: EventViewModel
    @ObservedObject var viewModel: HolidayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isDeleteAlertPresented = false
    @State private var eventToDelete: CalendarEvent? = nil
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    let holidayName = getHolidayName(for: date)
                    Section {
                        HStack {
                            Text(formattedDate(date))
                            Spacer()
                            Text(holidayName ?? "")
                                .font(.footnote)
                                .foregroundStyle(.holiday)
                        }
                    }
                    let eventsForDay = eventViewModel.events.filter { calendar.isDate($0.eventStartDate, inSameDayAs: date) }
                        .sorted { $0.eventStartDate < $1.eventStartDate } // ここで開始時刻順にソート
                    if eventsForDay.isEmpty {
                        Section {
                            Text("None")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } header: {
                            Text("No events for this date.")
                                .font(.headline)
                        }
                    } else {
                        ForEach(eventsForDay, id: \.id) { event in
                            Section {
                                
                                DisclosureGroup {
                                    if let memo = event.eventMemo, !memo.isEmpty {
                                        HStack {
                                            memoImage.font(.footnote)
                                            Text(memo)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                        }
                                    } else {
                                        Text("No memo available.")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                } label: {
                                    HStack {
                                        RoundedRectangle(cornerRadius: 10, style: .circular)
                                            .frame(width: 5, height: 25)
                                            .foregroundStyle(Color(decodeDataToColor(event.colorData)))
                                        Text(event.eventTitle)
                                            .font(.body)
                                        if event.allDay {
                                            Text("all day")
                                                .foregroundStyle(Color.gray)
                                        }
                                    }
                                }
                                .tint(.primary)
                            } header: {
                                HStack {
                                    Text("\(dateToString(event.eventStartDate)) - \(dateToString(event.eventEndDate))")
                                        .font(.headline)
                                    if let memo = event.eventMemo, !memo.isEmpty {
                                        memoImage.font(.footnote)
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    Spacer()
                                    Button(action: {
                                        eventToDelete = event
                                        isDeleteAlertPresented = true
                                    }){
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                }
                .animation(.default, value: isDeleteAlertPresented)
                .navigationTitle("Event details")
                .headerProminence(.increased)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .tint(.primary)
                            .fontWeight(.bold)
                            .font(.caption2)
                            .padding()
                    }
                }
            }
            .alert(isPresented: $isDeleteAlertPresented) {
                Alert(
                    title: Text("\(eventToDelete?.eventTitle ?? "Confirm deletion")"),
                    message: Text("Do you want to delete the event?"),
                    primaryButton: .cancel(Text("Cancel")){},
                    secondaryButton: .destructive(Text("Delete")) {
                        if let event = eventToDelete, !event.isInvalidated {
                            eventViewModel.deleteEvent(event)
                        } else {
                            print("This event has already been deleted.")
                        }
                    }
                )
            }
        }
        .fontDesign(.rounded)
    }
    
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
    
    private func getHolidayName(for date: Date) -> String? {
        guard let holiday = viewModel.holidays.first(where: { holiday in
            guard let holidayDate = holiday.dateFormatted else { return false }
            return Calendar.current.isDate(holidayDate, inSameDayAs: date)
        }) else {
            return nil
        }
        return holiday.name
    }
}

#Preview {
    ContentView()
}
