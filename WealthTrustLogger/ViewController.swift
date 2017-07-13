//
//  ViewController.swift
//  WealthTrustLogger
//
//  Created by Nikhil Dange on 12/07/17.
//  Copyright © 2017 learner. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UITableViewController,UISearchBarDelegate {
    
    var arrayOfAsset = [Assest]()
    var performSortOfType : SortType = .byAmount
    var doTableNeedsReload = false
    @IBOutlet weak var nameSearchBar: UISearchBar!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var sortTypeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.barTintColor = UIColor.black
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.white,
            NSFontAttributeName : UIFont(name: "Futura", size: 30)!
        ]
        
        if UserDefaults.standard.object(forKey: "loaded") == nil || UserDefaults.standard.object(forKey: "loaded") as! Bool? == false {
            downloadAndloadFileAssetIntoDatabase()
        }
        else {
            sortTable()
        }
    }
    
// MARK: - TableView Method
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let nameLabel = cell?.viewWithTag(101) as! UILabel
        let amountLabel = cell?.viewWithTag(102) as! UILabel
        let dateLabel = cell?.viewWithTag(103) as! UILabel
        
        nameLabel.text = arrayOfAsset[indexPath.row].name
        amountLabel.text =  "₹ "+String(arrayOfAsset[indexPath.row].amount)
        dateLabel.text = arrayOfAsset[indexPath.row].date
        return cell!
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfAsset.count
    }
    
// MARK: - SearchBar Method
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        nameSearchBar.showsCancelButton = true
        sortTypeSegmentedControl.isEnabled = false
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSortOfType = .byName(searchText: searchBar.text!)
        sortTable()
        doTableNeedsReload = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if doTableNeedsReload {
            doTableNeedsReload = false
            switch sortTypeSegmentedControl.selectedSegmentIndex {
            case 0:
                performSortOfType = .byAmount
            case 1:
                performSortOfType = .byDate
            default:
                break
            }
            sortTable()
        }
        nameSearchBar.text = ""
        nameSearchBar.showsCancelButton = false
        nameSearchBar.endEditing(true)
        sortTypeSegmentedControl.isEnabled = true
    }
    
// MARK: - Action Method
    
    @IBAction func didTapSortBySegmentedControl(_ sender: UISegmentedControl) {
        
        switch sortTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            performSortOfType = .byAmount
        case 1:
            performSortOfType = .byDate
        default: break
        }
        sortTable()
    }
    
    @IBAction func didTapOnRefreshButton(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func didTapOnDeleteTableButton(_ sender: UIBarButtonItem) {
        DatabaseManager.sharedDatabaseManager.deleteTable()
        UserDefaults.standard.set(false, forKey: "loaded")
        sortTable()
    }
    
    func sortTable() {
        DispatchQueue.global().async {
            switch self.performSortOfType {
            case .byAmount:
                self.arrayOfAsset = DatabaseManager.sharedDatabaseManager.sortBy(AmountOrDateOrName: .byAmount)
            case .byDate:
                self.arrayOfAsset = DatabaseManager.sharedDatabaseManager.sortBy(AmountOrDateOrName: .byDate)
            case .byName(let searchText):
                self.arrayOfAsset = DatabaseManager.sharedDatabaseManager.sortBy(AmountOrDateOrName: .byName(searchText: searchText))
            }
            DispatchQueue.main.async(execute: {
                self.countLabel.text = String(self.arrayOfAsset.count)+" Entries"
                self.tableView.reloadData()
            })
        }
    }
    
    func downloadAndloadFileAssetIntoDatabase() {
        let url = NSURL(string: "http://portal.amfiindia.com/spages/NAV0.txt")
        let data = NSData(contentsOf: url as! URL)
        data?.write(toFile: "/tmp/file.txt", atomically: true)
        //        let str = String(data: data as! Data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        doSortingDuringLoading(waitTime: 2)
        let operation : BlockOperation = BlockOperation(block: {
            let pathURL = URL(fileURLWithPath: (NSString(string:"/tmp/file.txt").expandingTildeInPath ))
            let s = StreamReader.init(url: pathURL)
            _ = s?.nextLine()
            while let inline = s?.nextLine() {
                let line = inline.replacingOccurrences(of: "\r", with: "")
                let splitArray = line.components(separatedBy: ";")
                if splitArray.count == 8 {
                    let id = DatabaseManager.sharedDatabaseManager.insertInTable(inName: splitArray[3], inAmount: Double(splitArray[4]) ?? 0, inDate: splitArray[7])
                    print("Inserted into Table with id:\(id)")
                }
            }
            UserDefaults.standard.set(true, forKey: "loaded")
        })
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1;
        operationQueue.addOperation(operation)
    }
    
    func doSortingDuringLoading(waitTime time: Double) {
        if UserDefaults.standard.object(forKey: "loaded") == nil || UserDefaults.standard.object(forKey: "loaded") as! Bool? == false {
            OperationQueue.main.addOperation {
                let i = time == 0 ? 5 : time;
//                print(i)
                self.perform(#selector(self.doSortingDuringLoading), with: nil, afterDelay: i)
                self.sortTable()
            }
        }
    }
}

