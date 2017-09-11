//
//  EditViewController.swift
//  Spicker
//
//  Created by KA on 2017/09/11.
//  Copyright © 2017年 KentaroAbe. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import NCMB

class EditViewController: UIViewController {
    let ap = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var Priority: UITextField!
    @IBOutlet weak var TaskName: UITextField!
    @IBOutlet weak var notificationTime: UIDatePicker!
    @IBOutlet weak var isNotification: UISwitch!
    
    var currentPriority = 0
    var newPriority = ""
    var newName = ""
    var newnotificationTime = 0.0;
    var dontnotification = false

    override func viewDidLoad(){
        super.viewDidLoad()
        //表示された時の処理を記述
        Priority.text = String(describing:ap.currentData_Prioroty!)
        TaskName.text = ap.currentData_Name!
        let notificationTime_UNIX = ap.currentData_notificationTime! - 3600*9
        print(notificationTime_UNIX)
        let notificationTime_Date = Date.init(timeIntervalSince1970: TimeInterval(notificationTime_UNIX))
        notificationTime.date = notificationTime_Date
        if ap.currentData_isNotification == true{
            isNotification.setOn(true, animated: true)
        }else{
            isNotification.setOn(true, animated: true)
        }
        self.currentPriority = ap.currentData_Prioroty!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func EditButton(_ sender: Any) {
        var isCanRegist = false
        if Priority.text == ""||TaskName.text == ""{
            isCanRegist = false
        }else{
            isCanRegist = true
        }
        if isCanRegist == true{
            let createAndDelete = CreateViewController()
            self.newName = self.TaskName.text!
            self.newPriority = String(describing:Int(self.Priority.text!)!-1)
            let newNotificationTime_Date = self.notificationTime.date
            let newNotificationTime_UNIX = newNotificationTime_Date.timeIntervalSince1970
            self.newnotificationTime = newNotificationTime_UNIX
            createAndDelete.DataDeletePerDay(dataKeyPriority: self.currentPriority)
            createAndDelete.DataAdd(Name: self.newName, Priority: self.newPriority, isNotification: self.isNotification.isOn, notificationTime: self.newnotificationTime)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
}
