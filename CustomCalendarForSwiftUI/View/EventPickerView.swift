//
//  EventPickerView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/01/07.
//

import SwiftUI
import RealmSwift

struct EventPickerView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @State private var pickerType: TripPicker = .scaled
    @State private var activeID: EventDate.ID?
    @Binding var selectedEvent: EventDate?
    @State private var isHideButton: Bool = false
    var buttonSize: CGFloat = 45 //55
    var events: [EventDate]
    var closeAction: () -> Void
    var onEventSelected: (EventDate) -> Void
    
    enum TripPicker: String, CaseIterable {
        case scaled = "Scaled"
        case normal = "Normal"
    }
    
    var body: some View {
        VStack {
            Spacer()
            GeometryReader {
                let size = $0.size
                let padding = (size.width - buttonSize) / 2
                VStack(spacing: 0) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 30) {
                            ForEach(events) { event in
                                Button {
                                    selectedEvent = event
                                    onEventSelected(event)
                                    closeAction()
                                } label: {
                                    let currentActiveID = activeID
                                    let currentPickerType = pickerType
                                    HStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .frame(width: 5, height: 30)
                                            .foregroundStyle(Color(decodeDataToColor(event.colorData)))
                                            .padding(.leading, 8)
                                        VStack(alignment: .leading, spacing: 5) {
                                            HStack {
                                                Text(event.eventTitle)
                                                    .font(.footnote)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                            }
                                            
                                            HStack(spacing: 3) {
                                                if event.allDay {
                                                    Text("All day")
                                                        .font(.caption)
                                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor).opacity(0.5))
                                                } else {
                                                    Text(event.eventStartDate)
                                                        .font(.caption2)
                                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                                    Text(event.eventEndDate)
                                                        .font(.caption2)
                                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                                }
                                            }
                                        }
                                        .frame(width: buttonSize * 1.6, height: buttonSize, alignment: .leading)
                                        .padding(.vertical, 5)
                                    }
                                    .background(
                                        decodeDataToColor(event.colorData)
                                            .opacity(0.4)
                                            .gradient,
                                        in: RoundedRectangle(cornerRadius: 10) // 角丸長方形に変更
                                    )
                                    
                                    .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)
                                    .visualEffect { view, proxy in
                                        view
                                            .offset(y: offset(proxy))
                                            .offset(y: scale(proxy) * 8)
                                    }
                                    .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                                        view
                                            .scaleEffect(phase.isIdentity && currentActiveID == event.id && currentPickerType == .scaled ? 1.5 : 1.0, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .frame(height: size.height * 0.9)
                        .offset(y: -10)
                        .scrollTargetLayout()
                    }

//                    ScrollView(.horizontal) {
//                        HStack(spacing: 35) {
//                            ForEach(events) { event in
//                                Button {
//                                    selectedEvent = event
//                                    onEventSelected(event)
//                                    closeAction()
//                                } label: {
//                                    let currentActiveID = activeID
//                                    let currentPickerType = pickerType
//                                    
//                                    Text(event.eventTitle.prefix(5)) // Display first letter of the event
//                                        .font(.footnote)
//                                        .fontWeight(.bold)
//                                        .foregroundStyle(Color.white)
//                                        .frame(width: buttonSize, height: buttonSize)
//                                        .background(decodeDataToColor(event.colorData).opacity(0.98).gradient, in: .circle)
//                                        .overlay(
//                                            Circle()
//                                                .stroke(decodeDataToColor(event.colorData), lineWidth: 0.5)
//                                            
//                                        )
//                                        .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)
//                                        .visualEffect { view, proxy in
//                                            view
//                                                .offset(y: offset(proxy))
//                                                .offset(y: scale(proxy) * 8)
//                                        }
//                                        .scrollTransition(.interactive, axis: .horizontal) { view, phase in
//                                            view
//                                                .scaleEffect(phase.isIdentity && currentActiveID == event.id && currentPickerType == .scaled ? 1.5 : 1.1, anchor: .bottom)
//                                        }
//                                }
//                            }
//                        }
//                        .frame(height: size.height * 0.9)
//                        .offset(y: -10)
//                        .scrollTargetLayout()
//                    }
                    Button(action: {
                        isHideButton.toggle()
                        closeAction() // 閉じるアクションを実行
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                            .font(.footnote).fontWeight(.bold)
                            .shadow(radius: 10)
                            .frame(width: 30, height: 30)
                            .padding(.bottom, 150) // 下部に配置
                    }
                    .symbolEffect(.bounce.down.wholeSymbol, value: isHideButton)
                }
                .safeAreaPadding(.horizontal, padding)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $activeID)
                .frame(height: size.height)
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.height > 0 {
                                withAnimation {
                                    closeAction()
                                }
                            }
                        }
                )
            }
            .frame(height: 200)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    nonisolated func offset(_ proxy: GeometryProxy) -> CGFloat {
        let progress = progress(proxy)
        return progress < 0 ? progress * -10 : progress * 10
    }
    
    nonisolated func scale(_ proxy: GeometryProxy) -> CGFloat {
        let progress = min(max(progress(proxy), -1), 1)
        return progress < 0 ? 1 + progress : 1 - progress
    }
    
    nonisolated func progress(_ proxy: GeometryProxy) -> CGFloat {
        let viewWidth = proxy.size.width
        let minX = (proxy.bounds(of: .scrollView)?.minX ?? 0)
        return minX / viewWidth
    }
    
    func decodeDataToColor(_ data: Data?) -> Color {
        guard let data = data,
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return .black
        }
        return Color(uiColor)
    }
    
}

#Preview {
    ContentView()
        .environmentObject(AppThemeManager())
}

