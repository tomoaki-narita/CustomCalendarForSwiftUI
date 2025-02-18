//
//  EditView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2024/12/27.
//

import SwiftUI
import RealmSwift
import EventKit

struct EditView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @State var isEditViewVisible: Bool = false
    @State var editingEvent: EventDate? = nil
    @State var eventListIsExpanded: Bool = true
    @ObservedResults(EventDate.self, sortDescriptor: SortDescriptor(keyPath: "sortOrder", ascending: true)) var events
    let plusImage: Image = Image(systemName: "plus")
    let clockImage: Image = Image(systemName: "clock")
    let memoImage: Image = Image(systemName: "note.text")
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color: themeManager.currentTheme.primaryColor, location: 0.25), .init(color: themeManager.currentTheme.gradientColor, location: 0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                List {
                    Section {
                        HStack {
                            Spacer()
                            Button {
                                isEditViewVisible = true
                                editingEvent = nil // 新規作成モード
                            } label: {
                                Text("\(plusImage) New event")
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            }
                            
                            .sheet(isPresented: $isEditViewVisible) {
                                CreateNewEventViewForEventDate(
                                    editingEvent: $editingEvent,
                                    selectedColor: .primary
                                )
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                    
                    Section(isExpanded: $eventListIsExpanded) {
                        ForEach(events, id: \.id) { event in
                            HStack {
                                Circle()
                                    .frame(width: 10)
                                    .foregroundStyle(decodeDataToColor(event.colorData))
                                Text(event.eventTitle)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                if let memo = event.eventMemo, !memo.isEmpty {
                                    memoImage.font(.footnote)
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                                }
                                Spacer()
                                HStack(spacing: 5) {
                                    if event.allDay {
                                        Text("All day")
                                            .font(.caption)
                                            .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                                    }
                                    Text("\(formatDate(event.eventStartDate))")
                                        .font(.footnote)
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                    Text("-")
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                    Text("\(formatDate(event.eventEndDate))")
                                        .font(.footnote)
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
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
                        }
                        .onDelete(perform: { index in
                            $events.remove(atOffsets: index)
                        })
                        .onMove(perform: moveEvent)
                    } header: {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .font(.headline)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            Text("Event template")
                                .fontWeight(.semibold)
                                .font(.headline)
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                        }
                    }
                    .frame(minHeight:40)
                    .tint(Color(themeManager.currentTheme.tertiaryColor))
                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))

//                    Section {
//                        Text("")
//                    }
//                    .frame(minHeight:40)
//                    .listRowBackground(Color(themeManager.currentTheme.secondaryColor))
                    
                }
                .scrollContentBackground(.hidden)
                .toolbar {
                    EditButton()
                        .tint(Color(themeManager.currentTheme.tertiaryColor))
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Event")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(themeManager.currentTheme.tertiaryColor)
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(themeManager.currentTheme.primaryColor), for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .listStyle(.sidebar)
                .headerProminence(.increased)
                .navigationBarBackButtonTextHidden()
                
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



#Preview {
    EditView()
        .environmentObject(AppThemeManager())
}
