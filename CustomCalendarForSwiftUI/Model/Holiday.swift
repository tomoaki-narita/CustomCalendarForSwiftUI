//
//  Untitled.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/01/27.
//

import SwiftUI
import RealmSwift


class HolidayViewModel: ObservableObject {
    @Published var holidays: [Holiday] = []
    private var realm: Realm

    init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Realmの初期化に失敗しました: \(error.localizedDescription)")
        }

        // Realmからデータを読み込む
        loadHolidaysFromRealm()

        // RealmにデータがなければAPIから取得
        if holidays.isEmpty {
            fetchHolidays()
        }
    }

    func fetchHolidays() {
        guard let url = URL(string: "https://holidays-jp.github.io/api/v1/date.json") else {
            print("URLが無効です")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("ネットワークエラー: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("データが取得できませんでした")
                return
            }

            do {
                let decoder = JSONDecoder()
                let holidayDict = try decoder.decode([String: String].self, from: data)
                let holidays = holidayDict.map { Holiday(date: $0.key, name: $0.value) }

                let sortedHolidays = holidays.sorted { $0.dateFormatted ?? Date() < $1.dateFormatted ?? Date() }

                DispatchQueue.main.async {
                    self.saveHolidaysToRealm(holidays: sortedHolidays)
                    self.loadHolidaysFromRealm() // Realmからデータを再読み込み
                }
            } catch {
                print("デコードエラー: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Realmから祝日データを読み込む
    func loadHolidaysFromRealm() {
        let realmHolidays = realm.objects(RealmHoliday.self).sorted(byKeyPath: "date", ascending: true)
        self.holidays = realmHolidays.map { Holiday(date: $0.date, name: $0.name) }
    }

    // Realmに祝日データを保存
    private func saveHolidaysToRealm(holidays: [Holiday]) {
        do {
            try realm.write {
                for holiday in holidays {
                    if realm.object(ofType: RealmHoliday.self, forPrimaryKey: holiday.date) == nil {
                        let realmHoliday = RealmHoliday()
                        realmHoliday.date = holiday.date
                        realmHoliday.name = holiday.name
                        realm.add(realmHoliday)
                    }
                }
            }
        } catch {
            print("Realm保存エラー: \(error.localizedDescription)")
        }
    }
}


struct Holiday: Identifiable, Decodable {
    var id: String { date }
    let date: String
    let name: String

    var dateFormatted: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

class RealmHoliday: Object {
    @Persisted(primaryKey: true) var date: String = ""
    @Persisted var name: String = ""
    
    func toDictionary() -> [String: Any] {
            return [
                "date": date,
                "name": name
            ]
        }
}
