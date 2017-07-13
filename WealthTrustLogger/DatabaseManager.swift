//
//  DatabaseManager.swift
//  WealthTrustLogger
//
//  Created by Nikhil Dange on 12/07/17.
//  Copyright © 2017 learner. All rights reserved.
//

import Foundation
import SQLite

enum SortType {
    case byAmount
    case byDate
    case byName(searchText:String)
}

struct Assest {
    let name: String
    let amount: Double
    let date: String
}

class DatabaseManager {
    static let sharedDatabaseManager:DatabaseManager = DatabaseManager()
    
    private let database : Connection?
    private let table = Table("wealth_table")
    private let id = Expression<Int64>("id")
    private let name = Expression<String>("name")
    private let amount = Expression<Double>("amount")
    private let date = Expression<Date>("date")
    private let SQLDateFormatter = DateFormatter()
    
    private init() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        do {
            database = try Connection("\(path)/wealth_connection.sqlite3")
            createTable()
        } catch {
            database = nil
            print ("Unable to OPEN database")
        }
        SQLDateFormatter.dateFormat = "dd-MMM-yyyy"
    }
    
    func createTable() {
        do {
            try database!.run(table.create(ifNotExists: true) { table in
                table.column(id, primaryKey: true)
                table.column(name)
                table.column(amount)
                table.column(date)
            })
            print("Created Table")
        } catch {
            print("Unable to CREATE")
        }
    }
    
    func insertInTable(inName: String, inAmount: Double, inDate: String) -> Int64? {
        do {
            let insert = table.insert(name <- inName, amount <- inAmount, date <- SQLDateFormatter.date(from: inDate)!)
            let id = try database!.run(insert)
            return id
        } catch {
            print("Unable to INSERT")
            return nil
        }
    }
    
    func deleteTable() {
        do {
            try database!.run(table.drop())
            print("Deleted Table")
        } catch {
            print("Unable to DELETE")
        }
    }
    
    func selectAll() -> [Assest] {
        var assetArray = [Assest]()
        do {
            for asset in try database!.prepare(self.table) {
                let newAsset = Assest(name: asset[name], amount: asset[amount], date: SQLDateFormatter.string(from: asset[date]))
                assetArray.append(newAsset)
            }
        } catch {
            print("Unable to SELECT ALL")
        }
//        for a in assetArray {
//            print("\(a)")
//        }
        return assetArray
    }
    
    func sortBy(AmountOrDateOrName inType:SortType) -> [Assest] {
        var assetArray = [Assest]()
        do {
            let sortQueryTable : Table
            switch inType {
            case .byAmount:
                sortQueryTable = table.order(amount.asc)
            case .byDate:
                sortQueryTable = table.order(date.asc)
            case .byName(let searchText):
                sortQueryTable = table.filter(name.like("%"+searchText+"%"))
            }
            for asset in try database!.prepare(sortQueryTable) {
                let newAsset = Assest(name: asset[name], amount: asset[amount], date: SQLDateFormatter.string(from: asset[date]))
                assetArray.append(newAsset)
            }
        } catch {
            print("Unable to SORT BY \(inType)")
        }
//        for a in assetArray {
//            print("\(a)")
//        }
        return assetArray
    }
}
