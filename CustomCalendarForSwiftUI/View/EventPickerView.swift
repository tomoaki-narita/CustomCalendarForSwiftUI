//
//  EventPickerView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/01/07.
//

import SwiftUI
import RealmSwift

struct EventPickerView: View {
    @State private var pickerType: TripPicker = .scaled
    @State private var activeID: EventDate.ID?
    @Binding var selectedEvent: EventDate?
    @State private var isHideButton: Bool = false
    var buttonSize: CGFloat = 50
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
                        HStack(spacing: 35) {
                            ForEach(events) { event in
                                Button {
                                    selectedEvent = event
                                    onEventSelected(event)
                                    //                                    print("Event selected: \(event.eventTitle) \(event.eventStartDate) - \(event.eventEndDate)")
                                    closeAction()
                                } label: {
                                    let currentActiveID = activeID
                                    let currentPickerType = pickerType
                                    
                                    Text(event.eventTitle.prefix(5)) // Display first letter of the event
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .frame(width: buttonSize, height: buttonSize)
                                        .background(decodeDataToColor(event.colorData).opacity(0.98).gradient, in: .circle)
                                        .overlay(
                                            Circle()
                                                .stroke(decodeDataToColor(event.colorData), lineWidth: 1)
                                            
                                        )
                                        .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)
                                        .visualEffect { view, proxy in
                                            view
                                                .offset(y: offset(proxy))
                                                .offset(y: scale(proxy) * 8)
                                        }
                                        .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                                            view
                                                .scaleEffect(phase.isIdentity && currentActiveID == event.id && currentPickerType == .scaled ? 1.5 : 1.1, anchor: .bottom)
                                        }
                                }
                            }
                        }
                        .frame(height: size.height * 0.9)
                        .offset(y: -10)
                        .scrollTargetLayout()
                    }
                    Button(action: {
                        isHideButton.toggle()
                        closeAction() // 閉じるアクションを実行
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.primary)
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
                //                .background(Color.red)
            }
            .frame(height: 200)
            //            .background(Color.red)
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
}

