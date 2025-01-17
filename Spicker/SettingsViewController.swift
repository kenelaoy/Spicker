//
//  SettingsViewController.swift
//  Spicker
//
//  Created by KentaroAbe on 2017/08/04.
//  Copyright © 2017年 KentaroAbe. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import NCMB
import RealmSwift
import Alamofire
import UserNotifications
import NotificationCenter

class SettingsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource,UIPickerViewDelegate,UIPickerViewDataSource {
    var yesOrTod = ["前日","当日"]
    var desc = 0
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return yesOrTod.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String {
        self.desc = row
        return yesOrTod[row]
    }
    
    
    @IBOutlet weak var TodayOrTom: UIPickerView!
    @IBOutlet weak var Time: UIDatePicker!
    @IBOutlet weak var isAgree: UISwitch!
    @IBOutlet weak var TableView: UITableView!
    
    var items: [JSON] = []
    
    var refreshControl:UIRefreshControl!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        let statusBar = UIView(frame:CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 20.0))
        statusBar.backgroundColor = UIColor.flatTeal
        
        view.addSubview(statusBar)

        print("表示されました")
        TodayOrTom.delegate = self
        TodayOrTom.dataSource = self
        let kurasu = CreateViewController()
        kurasu.permitCreate()
        let currentSettingsDB = try! Realm()
        let currentSettings = currentSettingsDB.objects(AppMetaData.self).sorted(byKeyPath: "ID", ascending: true)
        
        isAgree.setOn((currentSettings.last?.isSendDataPermission)!, animated: true)
        let currentTime = (currentSettings.first?.CloseTask)!
        let date = Date(timeIntervalSince1970: TimeInterval(currentTime))
        Time.date = date

        TableView.dataSource = self
        TableView.delegate = self
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
        refreshControl.addTarget(self, action: #selector(self.refreshControlValueChanged(sender:)), for: .valueChanged)
        self.TableView.addSubview(refreshControl)
        announce()
        TableView.reloadData()
        //isAgree.reloadInputViews()
        if currentSettings.first?.isToday == true{
            self.TodayOrTom.selectRow(1, inComponent: 0, animated: true)
        }else{
            self.TodayOrTom.selectRow(0, inComponent: 0, animated: true)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { //セルの内容がタップされた時の処理（データの変更画面）
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func announce() {
        items = []
        let url = "https://mb.api.cloud.nifty.com/2013-09-01/applications/GaasaqXiXrxQLyN6/publicFiles/oshirase.json"
        Alamofire.request(url).responseJSON{response in
            let json = JSON(response.result.value ?? 0)
            json.forEach{(_, data) in
                self.items.append(data)
            }
            self.TableView.reloadData()
        }
        
    }
    
    @IBAction func Save(_ sender: Any) {
        let database = try! Realm()
        print(Int(Time.date.timeIntervalSince1970))
        let rawTime = Time.date
        var nextTime = Int(rawTime.timeIntervalSince1970)
        print(nextTime)
        if self.desc == 1{ //当日指定の場合はNextTimeに１日プラス（今日は実行しない）
            nextTime += 3600*24
        }
        var TimeIn = Date(timeIntervalSince1970: TimeInterval(nextTime))
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm"
        let TimeInFormatted = format.string(from: TimeIn)
        let newFormat = "\(TimeInFormatted):00"
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let newDate = format.date(from: newFormat)
        
        var newDateUNIX = Int((newDate?.timeIntervalSince1970)!)
        
        let today = Date()
        if Int(today.timeIntervalSince1970) >= newDateUNIX{ //指定時間を既に過ぎている場合はNextTimeに１日プラス（今日は実行しない）
            newDateUNIX += 3600*24
        }
        print(newDateUNIX)
        
        
        
        let currentData = database.objects(AppMetaData.self).sorted(byKeyPath: "ID", ascending: false)
        
        var isToday = false
        
        if TodayOrTom.selectedRow(inComponent: 0) == 0{
            isToday = false
        }else{
            isToday = true
        }
        
        try! database.write(){
            currentData.first?.isToday = isToday
        }
        
        let notification = UNMutableNotificationContent()
        
        let WantFireNotificationTime = TimeInterval(newDateUNIX) - Date().timeIntervalSince1970
        
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: ["Spicker_Daily"])
        center.removeDeliveredNotifications(withIdentifiers: ["Spicker_Daily"])
        
        notification.title = "タスクは全部終わった？"
        notification.body = "早速次の日の予定を追加しましょう！"
        notification.sound = UNNotificationSound.default()
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: WantFireNotificationTime, repeats: false)
        let request = UNNotificationRequest.init(identifier: "Spicker_Daily", content: notification, trigger: trigger)
        
        center.add(request)
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { //セクション内の行数を返す
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Announce")
        cell.textLabel?.text = items[indexPath.row]["Contents"].string
        cell.detailTextLabel?.text = "掲載日：\(items[indexPath.row]["Date"].stringValue)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { //セクションタイトルを返す（"お知らせ"）
        return "お知らせ一覧"
    }
    
    @objc func refreshControlValueChanged(sender: UIRefreshControl) {
        announce()
        
        self.TableView.reloadData()
        
        sender.endRefreshing()
    }
    
    
    
}

