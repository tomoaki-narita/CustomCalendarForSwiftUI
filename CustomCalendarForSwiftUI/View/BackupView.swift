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
    @State private var showExporter = false
    @State private var exportData: Data?
    @State private var showImporter = false
    @State private var selectedImportURL: URL?
    @State private var activeAlert: AlertType? = nil
    @State private var errorMessage: String? = nil
    
    private let exportFlowString: Array = ["Tap the Export button", "When the backup confirmation pop-up appears, tap the OK button.", "When the \"Files\" app starts, \"Save\" (\"Move\") it to your desired location.", "The backup is complete when a \"Backup Successful\" pop-up appears."
    ]
    
    private let importFlowString: Array = ["Tap the Import button", "When the \"Files\" app starts, select the JSON file you want to import.", "When the import confirmation pop-up appears, tap the OK button.", "The import is complete when the \"Import Successful\" pop-up appears."
    ]
    
    private enum AlertType: Identifiable {
        case confirmBackup
        case backupSuccess
        case backupFailed
        case confirmImport
        case importSuccessful
        case importFailed
        case custom(String)
        
        var id: String {
            switch self {
            case .confirmBackup:
                return "Confirm Backup"
            case .backupSuccess:
                return "Backup Successful"
            case .backupFailed:
                return "Backup Failed"
            case .confirmImport:
                return "Confirm Import"
            case .importSuccessful:
                return "Import Successful"
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
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 20) {
                    HStack(alignment: .center) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Export")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top)
                    .foregroundStyle(.primary.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(exportFlowString, id: \.self) { item in
                            HStack(alignment: .top) {
                                Text("\(exportFlowString.firstIndex(of: item)! + 1).")
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text(item)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                        }
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    .foregroundStyle(.primary.opacity(0.8))
                    
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Import")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top)
                    .foregroundStyle(.primary.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(importFlowString, id: \.self) { item in
                            HStack(alignment: .top) {
                                Text("\(importFlowString.firstIndex(of: item)! + 1).")
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text(item)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .foregroundStyle(.primary.opacity(0.8))
                    
                    Spacer()
                    
                    HStack(spacing: 50) {
                    Button {
                        activeAlert = .confirmBackup
                    } label: {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                        .tint(.primary.opacity(0.8))
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
                            activeAlert = .backupSuccess
                        case .failure(let error):
                            print("エクスポート失敗: \(error.localizedDescription)")
                            activeAlert = .backupFailed
                        }
                    }
                    .frame(width: 100, height: 100)
                    .background {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                    
                    
                    Button {
                        showImporter = true  // ファイルアプリを開く
                    } label: {
                        VStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import")
                        }
                        .tint(.primary.opacity(0.8))
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
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Export & Import")
        }
        .alert(item: $activeAlert, content: createAlert)
        .fontDesign(.rounded)
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
        if let jsonString = String(data: data, encoding: .utf8) {
            print("インポートデータ: \(jsonString)")
        }
        let realm = try! Realm()
        let dateFormatter = ISO8601DateFormatter()
        do {
            // JSONの解析
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw ImportError.invalidFormat
            }
            // 必要なキーがあるかチェック
            if json["eventData"] == nil || json["calendarEventData"] == nil || json["holidayData"] == nil {
                throw ImportError.missingKeys
            }
            // データのインポート処理
            try realm.write {
                realm.deleteAll() // 既存データを削除
                // イベントデータの処理
                if let eventData = json["eventData"] as? [[String: Any]] {
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
                        realm.add(event)
                    }
                }
                // カレンダーイベントデータの処理
                if let calendarEventData = json["calendarEventData"] as? [[String: Any]] {
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
                        realm.add(event)
                    }
                }
                // 祝日データの処理
                if let holidayData = json["holidayData"] as? [[String: Any]] {
                    for dict in holidayData {
                        let holiday = RealmHoliday(value: dict)
                        realm.add(holiday)
                    }
                }
            }
            print("バックアップのインポートが完了しました")
            activeAlert = .importSuccessful
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
                secondaryButton: .cancel()
            )
            
        case .backupSuccess:
            return Alert(
                title: Text("Export Successful"),
                message: Text("Backup export succeeded."),
                dismissButton: .default(Text("Close")))
            
        case .backupFailed:
            return Alert(
                title: Text("Backup Failed"),
                message: Text("Export of backup failed."),
                dismissButton: .default(Text("Close")))
            
        case .confirmImport:
            return Alert(
                title: Text("Confirm Import"),
                message: Text("Do you want to import from the selected file?\nExisting calendar and event data will be deleted and replaced with the imported data."),
                primaryButton: .default(Text("Import")) {
                    if let url = selectedImportURL {
                        importRealmData(from: url)
                    }
                },
                secondaryButton: .cancel()
            )
            
        case .importSuccessful:
            return Alert(
                title: Text("Import Successful"),
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
}
