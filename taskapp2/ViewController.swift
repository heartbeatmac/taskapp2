//
//  ViewController.swift
//  taskapp2
//
//  Created by 永島利章 on 2017/12/01.
//  Copyright © 2017年 toshiaki.nagashima2. All rights reserved.
//

import UIKit
import RealmSwift   // ←追加
import UserNotifications    // 追加

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate {
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    @IBOutlet weak var tableView: UITableView!
    
    // Realmインスタンスを取得する
    
   
    
    let realm = try! Realm()  // ←追加
    

    
    // DB内のタスクが格納されるリスト。
    // 日付近い順\順でソート：降順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)  // ←追加
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
    }
    
    
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
    //    self.taskArray = try! Realm().objects(Task.self).filter("")
    
        // ここから
        
        // NSPredicateを使って検索条件を指定します
        let predicate = NSPredicate(format: "category = %@", searchText)
        
        self.taskArray = realm.objects(Task.self).filter(predicate)
        
  //      Results<Employee>().filter("company == %@", company)
    
        print("searchText: \(searchText)")

    // ここまで
   
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count  // ←追加する
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Cellに値を設定する.
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        // categoryはCellに値を返さなくて良い？
 //       task.category
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        
        let dateString:String = formatter.string(from: task.date as Date)
        cell.detailTextLabel?.text = dateString
        
        
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil) // ←追加する    }
        
        // セルが削除が可能なことを伝えるメソッド
        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCellEditingStyle {
            return UITableViewCellEditingStyle.delete
        }
        
        // Delete ボタンが押された時に呼ばれるメソッド
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
            
            if editingStyle == UITableViewCellEditingStyle.delete {
                // データベースから削除する  // ←以降追加する
                try! realm.write {
                    self.realm.delete(self.taskArray[indexPath.row])
                    tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
                }
            }
            
        }
        
    }
    
    
    // segue で画面遷移するに呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            task.date = NSDate()
            
            if taskArray.count != 0 {
                task.id = taskArray.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // 削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }    
    
    
    
}
