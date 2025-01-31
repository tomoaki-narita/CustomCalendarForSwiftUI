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
    
    let yearFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    var eventStore = EKEventStore()
    @State private var isShowDeniedAlert: Bool = false
    @State private var isShowExportSuccessful: Bool = false
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    private let calendar = Calendar.current
    @Environment(\.dismiss) private var dismiss
    @State private var eventsToCopy: [CalendarEvent] = []
    @State private var showNoEventsAlert: Bool = false
    @State private var showConfirmationAlert: Bool = false
    
    var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear + 5))
    }
    
    private let importFlowString: Array = ["Select year and month to export to iOS calendar.", "When the \"Confirm export\" pop-up appears, tap the Export button.", "The export is complete when you see a pop-up that says \"Export successful\"", "The calendar will be registered to the calendar specified in the \"Default Calendar\""
    ]
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 20) {
                    HStack(alignment: .center) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Export flow")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top)
                    .foregroundStyle(.primary.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(importFlowString, id: \.self) { item in
                            HStack(alignment: .top) {
                                Text("\(importFlowString.firstIndex(of: item)! + 1).")
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text(item)
                                    .font(.body)
                            }
                            
                        }
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    .foregroundStyle(.primary.opacity(0.8))
                    
                    HStack {
                        Text("Default calendar")
                        Spacer()
                        Text(getDefaultCalendarTitle())
                            .foregroundColor(getDefaultCalendarTitle() != getDefaultCalendarTitle() ? .primary : .gray)
                            .font(.body)
                    }
                    .frame(minHeight: 40)
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                    
                    HStack {
                        Spacer()
                        HStack(spacing: 0) {
                            Text("Year")
                            Picker("Year", selection: $selectedYear) {
                                ForEach(years, id: \.self) { year in
                                    Text("\(yearFormatter.string(from: NSNumber(value: year)) ?? "\(year)")").tag(year)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 0) {
                            Text("Month")
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text("\(month)").tag(month)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                        
                        Spacer()
                        
                    }
                    .frame(minHeight: 40)
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                    
                    Button {
                        fetchAndPrintEventsForSelectedMonth()
                    } label: {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                        .tint(.primary.opacity(0.8))
                        .fontWeight(.bold)
                    }
                    .frame(width: 100, height: 100)
                    .background {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                    .padding(.top)
                    Spacer()
                    
                }
                .padding(.horizontal)
            }
            .onAppear {
                confirmAuthThen {
                    print("Calendar access check completed")
                }
                if !authorizationStatus() {
                    isShowDeniedAlert.toggle()
                }
            }
            .navigationTitle("Export to iOS Cal")
        }
        .fontDesign(.rounded)
        .alert("Permission is required to access the calendar.", isPresented: $isShowDeniedAlert) {
            Button("Close", role: .cancel) {
                dismiss()
            }
            Button("Setting") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                dismiss()
            }
        } message: {
            Text("This app requires permission to access your calendar.")
        }
        .alert("No events found", isPresented: $showNoEventsAlert, actions: {
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
            Text("Do you want to export selected year and month events to iOS calendar?")
        })
        .alert("Export successful", isPresented: $isShowExportSuccessful, actions: {
            Button("Cancel", role: .cancel) {}
            Button("OK") {}
        }, message: {
            Text("Successfully exported to iOS calendar.")
        })
    }
    
    func confirmAuthThen(completion: @escaping () -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestWriteOnlyAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if self.authorizationStatus() {
                        print("already allowed")
                        completion()
                        return
                    } else {
                        eventStore.requestFullAccessToEvents { granted, error in
                            if granted {
                                print("allowed now")
                                DispatchQueue.main.async {
                                    completion()
                                }
                                return
                            } else {
                                print("Not allowed")
                            }
                        }
                    }
                }
            }
        } else {
            if authorizationStatus() {
                print("already allowed")
                completion()
                return
            } else {
                eventStore.requestAccess(to: .event, completion: { granted, error in
                    if !granted {
                        print("allowed now")
                        DispatchQueue.main.async {
                            completion()
                        }
                        return
                    } else {
                        print("Not allowed")
                    }
                })
            }
        }
    }
    
    func authorizationStatus() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess:
            print("Authorized")
            return true
        case .notDetermined:
            print("Not determined")
            return false
        case .restricted:
            print("Restricted")
            return false
        case .denied:
            print("Denied")
            return false
        case .writeOnly:
            print("Write only")
            return false
        @unknown default:
            print("Unknown default")
            return false
        }
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
    
    func getDefaultCalendarTitle() -> String {
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents?.title {
            return defaultCalendar
        } else {
            return "No default calendar found."
        }
    }
}

#Preview {
    CopyingIosCalendarEvents()
}
