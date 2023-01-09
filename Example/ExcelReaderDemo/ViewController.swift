//
//  ViewController.swift
//  ExcelReaderDemo
//
//  Created by FSKJ on 2023/1/9.
//

import UIKit
import ExcelReader

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let path = Bundle.main.path(forResource: "222", ofType: "xls")
//        let path = Bundle.main.path(forResource: "111", ofType: "xlsx")
        
        // to csv
        do {
            let csvPath = try ExcelReaderCore.shared.convertToCSV(path: path!)
            print("成功 - \(csvPath)")
        } catch {
            print("失败 - \(error.localizedDescription)")
        }
        
        // to txt
        do {
            let txtPath = try ExcelReaderCore.shared.convertToTXT(path: path!)
            print("成功 - \(txtPath)")
        } catch {
            print("失败 - \(error.localizedDescription)")
        }
    }


}
