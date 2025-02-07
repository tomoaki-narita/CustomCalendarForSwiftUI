//
//  BackupView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/01/28.
//

import SwiftUI
import RealmSwift
import UniformTypeIdentifiers

struct BackupView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @State private var showExporter = false
    @State private var exportData: Data?
    @State private var showImporter = false
    @State private var selectedImportURL: URL?
    @State private var activeAlert: AlertType? = nil
    @State private var errorMessage: String? = nil
    
    private let exportFlowString: [String] = [
        String(localized: "Tap the Export button"),
        String(localized: "When the backup confirmation pop-up appears, tap the Export button."),
        String(localized: "When the \"File\" app starts, \"Save\" (\"Move\") it to your desired location."),
        String(localized: "The backup is complete when a \"Export completed\" pop-up appears.")
    ]
    
    private let importFlowString: [String] = [
        String(localized: "Tap the Import button"),
        String(localized: "When the \"Files\" app starts, select the JSON file you want to import."),
        String(localized: "When the import confirmation pop-up appears, tap the Import button."),
        String(localized: "The import is complete when the \"Import completed\" pop-up appears.")
    ]
    
    private enum AlertType: Identifiable {
        case confirmBackup
        case backupCompleted
        case backupFailed
        case confirmImport
        case importCompleted
        case importFailed
        case custom(String)
        
        var id: String {
            switch self {
            case .confirmBackup:
                return "Confirm Backup"
            case .backupCompleted:
                return "Backup Completed"
            case .backupFailed:
                return "Backup Failed"
            case .confirmImport:
                return "Confirm Import"
            case .importCompleted:
                return "Import Completed"
            case .importFailed:
                return "Import Failed"
            case .custom(let message):
                return message
            }
        }
    }
    
    enum ImportError: Error {
        case invalidFormat
        case missingKeys
        
        var localizedDescription: String {
            switch self {
            case .invalidFormat:
                return "The file is not a valid JSON backup."
            case .missingKeys:
                return "The backup file is missing required data keys."
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(themeManager.currentTheme.primaryColor).ignoresSafeArea()
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(exportFlowString, id: \.self) { item in
                                HStack(alignment: .top) {
                                    Text("\(exportFlowString.firstIndex(of: item)! + 1).")
                                        .font(.footnote)
                                        .fontWeight(.bold)
                                    Text(item)
                                        .font(.footnote)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                        .padding(.horizontal)
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
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Import")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding(.top)
                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                    }
                    .listRowBackground(Color.clear)
                    
                    Section {
                        HStack(spacing: 50) {
                            Spacer()
                            
                            Button {
                                activeAlert = .confirmBackup
                            } label: {
                                VStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export")
                                }
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                .fontWeight(.bold)
                            }
                            .fileExporter(
                                isPresented: $showExporter,
                                document: exportData.map { BackupFile(data: $0) } ?? BackupFile(data: Data()),
                                contentType: .json,
                                defaultFilename: "calendar_backup"
                            ) { result in
                                switch result {
                                case .success(let url):
                                    print("バックアップ保存成功: \(url)")
                                    activeAlert = .backupCompleted
                                case .failure(let error):
                                    print("エクスポート失敗: \(error.localizedDescription)")
                                    activeAlert = .backupFailed
                                }
                            }
                            .frame(width: 100, height: 100)
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(themeManager.currentTheme.secondaryColor))
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                showImporter = true  // ファイルアプリを開く
                            } label: {
                                VStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import")
                                }
                                .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                .fontWeight(.bold)
                            }
                            .fileImporter(
                                isPresented: $showImporter,
                                allowedContentTypes: [.json]
                            ) { result in
                                switch result {
                                case .success(let url):
                                    selectedImportURL = url
                                    activeAlert = .confirmImport
                                case .failure(let error):
                                    print("インポート失敗: \(error.localizedDescription)")
                                    activeAlert = .importFailed
                                }
                            }
                            .frame(width: 100, height: 100)
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(themeManager.currentTheme.secondaryColor))
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .headerProminence(.increased)
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Export and Import")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(themeManager.currentTheme.tertiaryColor)
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(themeManager.currentTheme.primaryColor), for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonTextHidden()
            }
        }
        .alert(item: $activeAlert, content: createAlert)
    }
    
    func exportRealmData() -> Data? {
        let realm = try! Realm()
        let eventData = Array(realm.objects(EventDate.self)).map { $0.toDictionary() }
        let calendarEventData = Array(realm.objects(CalendarEvent.self)).map { $0.toDictionary() }
        let holidayData = Array(realm.objects(RealmHoliday.self)).map { $0.toDictionary() }
        let backupDict: [String: Any] = [
            "eventData": eventData,
            "calendarEventData": calendarEventData,
            "holidayData": holidayData
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: backupDict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("エクスポートデータ: \(jsonString)")
            }
            return jsonData
        } catch {
            print("JSON変換エラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importRealmData(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("ファイルへのアクセス権がありません")
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            print("ファイル読み込み失敗: \(url.path)")
            url.stopAccessingSecurityScopedResource()
            return
        }
        
        let realm = try! Realm()
        let dateFormatter = ISO8601DateFormatter()
        
        do {
            // JSONの解析
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw ImportError.invalidFormat
            }
            
            // イベントデータの処理
            if let eventData = json["eventData"] as? [[String: Any]] {
                try realm.write {
                    for var dict in eventData {
                        if let base64String = dict["colorData"] as? String,
                           let decodedData = Data(base64Encoded: base64String) {
                            dict["colorData"] = decodedData
                        }
                        
                        if let startDateString = dict["eventStartDate"] as? String,
                           let startDate = dateFormatter.date(from: startDateString) {
                            dict["eventStartDate"] = startDate
                        }
                        if let endDateString = dict["eventEndDate"] as? String,
                           let endDate = dateFormatter.date(from: endDateString) {
                            dict["eventEndDate"] = endDate
                        }
                        
                        let event = EventDate(value: dict)
                        // 既存の主キーがあれば更新、なければ追加
                        realm.add(event, update: .modified)
                    }
                }
            }
            
            // カレンダーイベントデータの処理
            if let calendarEventData = json["calendarEventData"] as? [[String: Any]] {
                try realm.write {
                    for var dict in calendarEventData {
                        if let startDateString = dict["eventStartDate"] as? String,
                           let startDate = dateFormatter.date(from: startDateString) {
                            dict["eventStartDate"] = startDate
                        }
                        if let endDateString = dict["eventEndDate"] as? String,
                           let endDate = dateFormatter.date(from: endDateString) {
                            dict["eventEndDate"] = endDate
                        }
                        
                        if let base64String = dict["colorData"] as? String,
                           let decodedData = Data(base64Encoded: base64String) {
                            dict["colorData"] = decodedData
                        }
                        
                        let event = CalendarEvent(value: dict)
                        realm.add(event, update: .modified)
                    }
                }
            }
            
            // 祝日データの処理
            if let holidayData = json["holidayData"] as? [[String: Any]] {
                try realm.write {
                    for dict in holidayData {
                        let holiday = RealmHoliday(value: dict)
                        realm.add(holiday, update: .modified)
                    }
                }
            }
            
            print("バックアップのインポートが完了しました")
            activeAlert = .importCompleted
        } catch {
            print("インポートエラー: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            activeAlert = .importFailed
        }
        // セキュリティスコープを解放
        url.stopAccessingSecurityScopedResource()
    }
    
    
    private func createAlert(for alertType: AlertType) -> Alert {
        switch alertType {
            
        case .confirmBackup:
            return Alert(
                title: Text("Backup Confirmation"),
                message: Text("Do you want to create a backup file?\nExport to “Files” App."),
                primaryButton: .default(Text("Export")) {
                    if let data = exportRealmData() {
                        exportData = data
                        showExporter = true
                    } else {
                        activeAlert = .backupFailed
                    }
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
            
        case .backupCompleted:
            return Alert(
                title: Text("Export completed"),
                message: Text("Backup export completed."),
                dismissButton: .default(Text("Close")))
            
        case .backupFailed:
            return Alert(
                title: Text("Backup Failed"),
                message: Text("Export of backup failed."),
                dismissButton: .default(Text("Close")))
            
        case .confirmImport:
            return Alert(
                title: Text("Confirm Import"),
                message: Text("Do you want to import from a file of your choice?\nExisting calendar events and event data will be preserved."),
                primaryButton: .default(Text("Import")) {
                    if let url = selectedImportURL {
                        importRealmData(from: url)
                    }
                },
                secondaryButton: .cancel()
            )
            
        case .importCompleted:
            return Alert(
                title: Text("Import completed"),
                message: Text("The backup was successfully imported."),
                dismissButton: .default(Text("Close")))
            
        case .importFailed:
            return Alert(
                title: Text("Import Failed"),
                message: Text(errorMessage ?? "The backup file format is incorrect."),
                dismissButton: .default(Text("OK"))
            )
            
        case .custom(let message):
            return Alert(
                title: Text("Error"),
                message: Text(message),
                dismissButton: .default(Text("OK")))
        }
    }
}

struct BackupFile: FileDocument {
    
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw NSError(domain: "BackupFile", code: -1, userInfo: [NSLocalizedDescriptionKey: "ファイルの読み込みに失敗しました"])
        }
        self.data = fileData
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    BackupView()
        .environmentObject(AppThemeManager())
}
