//
//  CopyEventForIosCalendar.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/01/30.
//

import SwiftUI
import EventKit
import RealmSwift

struct CopyingIosCalendarEvents: View {
    @EnvironmentObject var themeManager: AppThemeManager
    let yearFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    var eventStore = EKEventStore()
    @State private var isShowExportSuccessful: Bool = false
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    private let calendar = Calendar.current
    @Environment(\.dismiss) private var dismiss
    @State private var eventsToCopy: [CalendarEvent] = []
    @State private var showNoEventsAlert: Bool = false
    @State private var showConfirmationAlert: Bool = false
    @State private var showDefaultCalendarAlert: Bool = false
    
    var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear + 5))
    }
    
    private let importFlowString: [String] = [
        String(localized: "Select \"year\" and \"month\" to export to iOS Calendar."),
        String(localized: "When the \"Confirm export\" pop-up appears, tap the Export button."),
        String(localized: "The export is complete when you see a pop-up that says \"Export completed\""),
        String(localized: "* It will be registered in the calendar specified as \"Default calendar\"")
    ]
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color: themeManager.currentTheme.primaryColor, location: 0.25), .init(color: themeManager.currentTheme.gradientColor, location: 0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(importFlowString, id: \.self) { item in
                                HStack(alignment: .top) {
                                    Text("\(importFlowString.firstIndex(of: item)! + 1).")
                                        .font(.footnote)
                                        .fontWeight(.bold)
                                    Text(item)
                                        .font(.footnote)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                    } header: {
                        HStack(alignment: .center) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Export")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding(.top)
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                    }
                    .listRowBackground(Color.clear)
                    
//                    Section {
//                        Text(getDefaultCalendarTitle())
//                            .foregroundColor(getDefaultCalendarTitle() == getDefaultCalendarTitle() ? .primary : .black.opacity(0.3))
//                            .font(.body)
//                            .onTapGesture {
//                                showDefaultCalendarAlert.toggle()
//                            }
//                    } header: {
//                        Text("Default calendar")
//                    }
//                    .listRowBackground(Color(.systemGray4).opacity(0.3))
                    
                    Section {
                        HStack(spacing: 0) {
                            Spacer()
                            Text("Year")
                                Picker("Year", selection: $selectedYear) {
                                    ForEach(years, id: \.self) { year in
                                        Text("\(yearFormatter.string(from: NSNumber(value: year)) ?? "\(year)")").tag(year)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color(themeManager.currentTheme.tertiaryColor))
                                .labelsHidden()
                            
                            Spacer()
                            
                            Text("Month")
                                Picker("Month", selection: $selectedMonth) {
                                    ForEach(1...12, id: \.self) { month in
                                        Text("\(month)").tag(month)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color(themeManager.currentTheme.tertiaryColor))
                                .labelsHidden()
                            
                            Spacer()
                        }
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                    }
                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                    
                    Section {
                        HStack {
                            Spacer()
                            Button {
                                fetchAndPrintEventsForSelectedMonth()
                            } label: {
                                VStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export")
                                }
                                .tint(Color(themeManager.currentTheme.tertiaryColor))
                                .fontWeight(.bold)
                            }
                            .frame(width: 100, height: 100)
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(themeManager.currentTheme.secondaryColor))
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("iOS Calendar")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(themeManager.currentTheme.tertiaryColor)
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(themeManager.currentTheme.primaryColor), for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .headerProminence(.increased)
                .scrollContentBackground(.hidden)
                .navigationBarBackButtonTextHidden()

            }
            .navigationTitle("iOS Calendar")
        }
        .alert("There are no events", isPresented: $showNoEventsAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text("No events were found for the selected month.")
        })
        .alert("Confirm export", isPresented: $showConfirmationAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Export") {
                registerEventsToEventKit()
            }
        }, message: {
            Text("Would you like to export the selected month's events to your iOS calendar?")
        })
        .alert("Export completed", isPresented: $isShowExportSuccessful, actions: {
            Button("OK") {}
        }, message: {
            Text("Export to iOS calendar is completed.")
        })
//        .alert("Change the default calendar", isPresented: $showDefaultCalendarAlert, actions: {
//            Button("OK") {}
//        }, message: {
//            VStack {
//                Text("\"Settings app\" → \"Apps\" → \"Calendar\" → \"Default Calendar\"")
//            }
//        })
    }
    
    func fetchAndPrintEventsForSelectedMonth() {
        let startOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let realm = try! Realm()
        let events = realm.objects(CalendarEvent.self)
            .filter("eventStartDate >= %@ AND eventEndDate < %@", startOfMonth, endOfMonth)
        eventsToCopy = Array(events) // Store events in a state variable
        for event in eventsToCopy {
            print("Title: \(event.eventTitle), Start: \(event.eventStartDate), End: \(event.eventEndDate), isAllday: \(event.allDay)")
        }
        if eventsToCopy.isEmpty {
            showNoEventsAlert = true
        } else {
            showConfirmationAlert = true
        }
    }
    
    func registerEventsToEventKit() {
        // デフォルトのカレンダーを設定
        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
            print("Failed to get default calendar")
            return
        }
        var success = false
        for event in eventsToCopy {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = event.eventTitle
            ekEvent.startDate = event.eventStartDate
            ekEvent.endDate = event.eventEndDate
            ekEvent.isAllDay = event.allDay
            ekEvent.calendar = defaultCalendar
            do {
                try eventStore.save(ekEvent, span: .thisEvent)
                print("Event saved to iOS calendar: \(event.eventTitle)")
                success = true
            } catch {
                print("Failed to save event: \(error.localizedDescription)")
            }
        }
        if success {
            DispatchQueue.main.async {
                isShowExportSuccessful.toggle()
            }
        }
    }
    
//    func getDefaultCalendarTitle() -> String {
//        if let defaultCalendar = eventStore.defaultCalendarForNewEvents?.title {
//            return defaultCalendar
//        } else {
//            return "No default calendar found."
//        }
//    }
}

#Preview {
    CopyingIosCalendarEvents()
        .environmentObject(AppThemeManager())
}
