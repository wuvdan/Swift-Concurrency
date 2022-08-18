//
//  ViewController.swift
//  Swift Concurrency
//
//  Created by 吴丹 on 2022/8/8.
//

import UIKit
import Combine
import SwiftyJSON

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            
            DLoading.showToast(titleColor: .white, backgroundColor: .black, maskColor: .black, title: "数据请求失败，请稍后重试", delay: .infinity) {
                print("----")
            }
            
            NetworkManager.manager
                .setURL("https://www.mxnzp.com/api/weather/forecast/合肥市")
                .setHeaders( [
                    "app_id": "almxgpklqjfuephk",
                    "app_secret": "MlRHaTRPUFZkZzd6U0ZoYmw2ZGJTQT09"
                ])
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
                .sink { (completion) in
                       switch completion {
                       case .finished:
                           break
                       case .failure(let error):
                           print(error.localizedDescription)
                       }
                    } receiveValue: { (response) in
                        /// The response of data type is Data.
                        /// T##Here: decode JSON Data into your custom model structure / class
                        print(JSON(response))
//                        DLoading.hidenLoading()
                    }
                    .cancel()
        }
            
    }

}

