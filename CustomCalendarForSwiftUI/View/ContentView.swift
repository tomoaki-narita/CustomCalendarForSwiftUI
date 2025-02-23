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
    @State private var selectedEvent: EventDate?
    @State private var isPickerVisible: Bool = false
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var showEventPickerView: Bool = false
    @State private var activeAlert: AlertType? = nil
    @State private var isReloadButton: Bool = false
    @State private var isPlusButton: Bool = false
    @State private var showConfirmationDialog: Bool = false
    @State private var eventToProcess: EventDate?
    private let calendar = Calendar.current
    @ObservedResults(EventDate.self, sortDescriptor: SortDescriptor(keyPath: "sortOrder", ascending: true)) var events
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var viewModel = HolidayViewModel()
    @State private var tappedDate: Date? = nil  // ロングタップされた日付
    @State private var blurEffectView: UIVisualEffectView?
    
    @State private var showDuplicateAlert = false
    @State private var duplicateEventTitle: String = ""
    @State private var duplicateEventDate: String = ""
    @State private var duplicateEventColor: String = ""
    
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var themeManager: AppThemeManager
    
    private enum AlertType: Identifiable {
        case noDateSelected
        case custom(String)
        
        var id: String {
            switch self {
            case .noDateSelected:
                return "No date selected"
            case .custom(let message):
                return message
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color: themeManager.currentTheme.primaryColor, location: 0.25), .init(color: themeManager.currentTheme.gradientColor, location: 0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                VStack {
                    CalendarView(
                        currentMonth: $currentMonth,
                        selectedDates: $selectedDates,
                        isPickerVisible: $isPickerVisible,
                        selectedYear: $selectedYear,
                        selectedMonth: $selectedMonth,
                        events: eventViewModel.events,
                        onLongTap: { date in
                            tappedDate = date  // ロングタップされた日付を保存
                        },
                        viewModel: viewModel
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .blur(radius: showEventPickerView ? 2.5 : 0)
                    .allowsHitTesting(!showEventPickerView)
                    
                    HStack {
                        Spacer()
                        Button(action:{
                            isReloadButton.toggle()
                            resetCalendar()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                .font(.title3)
                                .padding()
                                .shadow(radius: 10)
                        }
                        .symbolEffect(.bounce.down.wholeSymbol, value: isReloadButton)
                        .disabled(isPickerVisible)
                        Spacer()
                        Button(action: {
                            isPlusButton.toggle()
                            if selectedDates == [] {
                                activeAlert = .noDateSelected
                            } else {
                                withAnimation(.snappy(duration: 0.5)) {
                                    showEventPickerView.toggle()
                                }
                            }
                            
                        }) {
                            Image(systemName: "square.stack")
                                .rotationEffect(.degrees(90))
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                .font(.title2)
                                .padding()
                                .shadow(radius: 10)
                        }
                        .symbolEffect(.bounce.down.wholeSymbol, value: isPlusButton)
                        .disabled(isPickerVisible)
                        
                        Spacer()
                        NavigationLink(destination: EditView()) {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                .font(.title3)
                                .padding()
                                .shadow(radius: 10)
                        }
                        Spacer()
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                .font(.title3)
                                .padding()
                                .shadow(radius: 10)
                        }
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .allowsHitTesting(!showEventPickerView) //opacityが0になるとタップできなくなるため不要だが一応残す
                    .opacity(showEventPickerView ? 0 : 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .padding(.horizontal)
                .sheet(item: $tappedDate) { date in
                    NavigationStack {
                        EventDetailModal(date: date, eventViewModel: eventViewModel, viewModel: viewModel)
                            .environmentObject(eventViewModel)
                            .presentationDetents([.large])
                    }
                    
                }
                .onAppear {
                    eventViewModel.fetchEvents()
                }
                .onChange(of: scenePhase) { newPhase, error in
                    if newPhase == .background || newPhase == .inactive {
                        // アプリがバックグラウンドまたは非アクティブになったときにブラーを追加
                        removeBlurEffect()
                    } else if newPhase == .active {
                        // アプリがフォアグラウンドに戻ったときにブラーを削除
                        addBlurEffect()
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .overlay {
            if showEventPickerView {
                EventPickerView(
                    selectedEvent: $selectedEvent,
                    events: Array(events)
                ) {
                    withAnimation(.snappy(duration: 1.5)) {
                        showEventPickerView = false
                    }
                } onEventSelected: { event in
                    // イベント選択時にダイアログを表示
                    eventToProcess = event
                    showConfirmationDialog = true
                }
                .transition(.move(edge: .bottom))
            }
        }
        .confirmationDialog(
            "\(eventToProcess?.eventTitle ?? "event title")",
            isPresented: $showConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Register", role: .none) {
                if let event = eventToProcess {
                    processEvent(event)
                    selectedDates.removeAll() // 選択を解除
                    selectedEvent = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Register event to selected date.")
        }
        .alert(item: $activeAlert, content: createAlert)
        .alert("Duplicate events", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Title: \(duplicateEventTitle)\nDate: \(duplicateEventDate) \nColor: \(duplicateEventColor)\nThis event is already registered for the selected date.")
        }
    }
    
    private func resetCalendar() {
        currentMonth = 0 // 現在の月に戻す
        selectedDates.removeAll() // 選択を解除
        selectedEvent = nil
        isPickerVisible = false // ピッカーを閉じる
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
    
    private func createAlert(for alertType: AlertType) -> Alert {
        switch alertType {
        case .noDateSelected:
            return Alert(title: Text(alertType.id), message: Text("Please select a date."), dismissButton: .default(Text("OK")))
            
        case .custom(let message):
            return Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
        }
    }
    
    func combineDateAndTime(dateString: String, timeString: String) -> Date? {
        // 結合したフォーマット例: "2025-01-31 20:44:00"
        let combinedString = "\(dateString) \(timeString)"
        
        // DateFormatterの設定
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm" // 秒を含めたフォーマットに変更
        formatter.locale = Locale(identifier: "en_US_POSIX") // 安定したパースのための設定
        
        // Date型に変換
        return formatter.date(from: combinedString)
    }
    
    /// イベントを処理する関数
    private func processEvent(_ event: EventDate) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let selectedDatesStrings = selectedDates.map { formatter.string(from: $0) }
        
        let eventStartTime = event.eventStartDate
        let eventEndTime = event.eventEndDate
        
        for dateString in selectedDatesStrings {
            guard let combinedStartDate = combineDateAndTime(dateString: dateString, timeString: eventStartTime),
                  let combinedEndDate = combineDateAndTime(dateString: dateString, timeString: eventEndTime) else {
                print("開始日時または終了日時の変換に失敗しました")
                continue
            }
            
            // **イベントの重複チェック（タイトル・開始・終了・色）**
            if let duplicateEvent = eventViewModel.events.first(where: {
                $0.eventTitle == event.eventTitle &&
                $0.eventStartDate == combinedStartDate &&
                $0.eventEndDate == combinedEndDate &&
                $0.colorData == event.colorData
            }) {
                // **重複したイベントがある場合、アラートを表示**
                duplicateEventTitle = duplicateEvent.eventTitle
                duplicateEventDate = dateString
                if let colorData = duplicateEvent.colorData,
                   let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                    duplicateEventColor = uiColor.toHexString()
                } else {
                    duplicateEventColor = "Unknown Color"
                }

                showDuplicateAlert = true
                print("⚠️ 重複イベント: \(duplicateEventTitle) - \(duplicateEventDate) (色: \(duplicateEventColor))")
                continue
            }
            
            print("✅ 登録: \(event.eventTitle) - \(combinedStartDate) (色: \(String(describing: event.colorData)))")
            
            let calendarEvent = CalendarEvent(
                eventTitle: event.eventTitle,
                eventStartDate: combinedStartDate,
                eventEndDate: combinedEndDate,
                eventMemo: event.eventMemo,
                allDay: event.allDay,
                sortOrder: event.sortOrder,
                colorData: event.colorData
            )
            eventViewModel.addEvent(calendarEvent)
        }
    }

//    func saveEventToRealm(event: CalendarEvent) {
//        do {
//            let realm = try Realm()
//            try realm.write {
//                realm.add(event)
//            }
//            print("イベントが正常に保存されました: \(event.eventTitle)")
//            resetCalendar()
//        } catch {
//            print("イベントの保存に失敗しました: \(error.localizedDescription)")
//        }
//    }
    
    private func fetchAndPrintSavedEvents() {
        do {
            let realm = try Realm()
            let savedEvents = realm.objects(CalendarEvent.self) // データを全件取得
            
            for event in savedEvents {
                print("イベントID: \(event.id)")
                print("タイトル: \(event.eventTitle)")
                print("開始日時: \(event.eventStartDate)")
                print("終了日時: \(event.eventEndDate)")
                print("メモ: \(event.eventMemo ?? "なし")")
                print("終日: \(event.allDay)")
                print("ソート順: \(event.sortOrder)")
                print("イベントカラー: \(event.colorData ?? Data())")
                print("--------------------------")
            }
        } catch {
            print("データの取得に失敗しました: \(error.localizedDescription)")
        }
    }
    
    func addBlurEffect() {
        guard blurEffectView == nil else { return }
        // UIApplicationからwindowSceneとwindowを安全に取得
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            // ブラーエフェクトを作成
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView?.alpha = 0.0
            // ウィンドウのサイズに合わせてブラーエフェクトのサイズを設定
            blurEffectView?.frame = window.bounds
            if scenePhase == .inactive || scenePhase == .background{
                window.addSubview(blurEffectView!)
                //iconの名前。Assets.xcassetsに任意の画像
                if let appIcon = UIImage(named: "appIconImage") {
                    let iconImageView = UIImageView(image: appIcon)
                    //bulurに乗せるiconの大きさ
                    let iconSize: CGFloat = 100
                    //iconの表示位置
                    iconImageView.frame = CGRect(x: (window.bounds.width - iconSize) / 2,
                                                 y: (window.bounds.height - iconSize) / 2,
                                                 width: iconSize,
                                                 height: iconSize
                    )
                    iconImageView.clipsToBounds = true
                    iconImageView.contentMode = .scaleAspectFit
                    iconImageView.alpha = 0.0
                    iconImageView.layer.cornerRadius = 20
                    blurEffectView?.contentView.addSubview(iconImageView)
                    UIView.animate(withDuration: 0.2) {
                        self.blurEffectView?.alpha = 1.0
                        iconImageView.alpha = 1.0
                    }
                }
            }
        } else {
            print("ウィンドウが取得できませんでした")
        }
    }
    
    func removeBlurEffect() {
        // ブラーが存在する場合にのみ削除
        if scenePhase == .active {
            UIView.animate(withDuration: 0.2, animations: {
                self.blurEffectView?.alpha = 0.0
            }, completion: { _ in
                blurEffectView?.removeFromSuperview()
                blurEffectView = nil // メモリを解放
            })
        }
    }
}

extension Date: @retroactive Identifiable {
    public var id: String {
        return String(self.timeIntervalSince1970)
    }
}

extension UIColor {
    func toHexString() -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "#000000" // 黒をデフォルト
        }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}


struct NavigationBarBackButtonTextHidden: ViewModifier {
  @Environment(\.presentationMode) var presentaion
  @EnvironmentObject var themeManager: AppThemeManager
    
  func body(content: Content) -> some View {
    content
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: { presentaion.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.backward")
                  .font(.footnote.bold())
                  .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
          }
        }
      }
  }
}

extension View {
  func navigationBarBackButtonTextHidden() -> some View {
    return self.modifier(NavigationBarBackButtonTextHidden())
  }
}


#Preview {
    ContentView()
        .environmentObject(AppThemeManager())
}
