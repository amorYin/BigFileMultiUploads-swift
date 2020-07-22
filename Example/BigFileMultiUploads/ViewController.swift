//
//  ViewController.swift
//  BigFileMultiUploads
//
//  Created by droudrou@hotmail.com on 07/09/2020.
//  Copyright (c) 2020 droudrou@hotmail.com. All rights reserved.
//

import UIKit
import BigFileMultiUploads
import Photos
import CoreServices

class ViewController: UIViewController,UUPItf {
  
    @IBOutlet weak var text1: UILabel!
    @IBOutlet weak var text2: UILabel!
    @IBOutlet weak var text3: UILabel!
    @IBOutlet weak var text4: UILabel!
    @IBOutlet weak var text5: UILabel!
    @IBOutlet weak var text6: UILabel!
    var mItem:UUPItem?
    
    @objc func onUPCancel(_ item: UUPItem) {
        
    }
    
    @objc func onConfigure() -> UUPConfig {
        UUPConfig.default.authSign = "N2VmYWxlY21peHhUd3ovNG44cWhJSkhtN0tWeTN5bDk5R3pKTGtueHBWYTJ2bTJ5c0ZSZzNQVyszdmtCRFJlcUJ4TEF0ZG1UcUtIbldkenNVY0tmZWtSWUNuQ1VFVDdpRmgvNUZVUmpqWEhCaFN4ejBhTXJ3Y2JodnFqdzgvMFNpUlBUbVYzQTBDU0NLbmJSZGNoclh4dnd0bE9TUDk3clc4ejhObXlJakNxb2tMZjN3eXNMMTdFdTJTOEJBcUtYRW9zRkJxNUZOZE9YRnNIc3dJbVB2TDg3WmdTd1BkWmJMbjkwbmdOSzZmUlF6d1RqYTNIOEs0a3B2aTh1empQQUpsckw="
        UUPConfig.default.deviceToken = "N2VmYWxlY21peHhUd3ovNG44cWhJSkhtN0tWe="
        return UUPConfig.default
    }
    
    @objc func onUPStart(_ item: UUPItem) {
        print("\(item.mProgress)====5")
    }
    
    @objc func onUPFinish(_ item: UUPItem) {
        print("\(item.mProgress)====0")
    }
    
    @objc func onUPProgress(_ item: UUPItem) {
        print("\(item.mProgress)====1===\(item.mSpeedStr ?? "")")
    }
    
    @objc func onUPError(_ item: UUPItem) {
        print("\(item.mError)====2")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        let item = UUPItem(url: URL.init(string: ".")!, type: .IMAGE)
//        UUPManager.share(with: self)?.start(item)
//
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+10) {
//            UUPNetworkRM.default?.startMonitoring()
//            UUPManager.destroy()
//        }
//        
//        let item2 = UUPItem(url: URL.init(string: ".")!, type: .IMAGE)
//        UUPManager.share(with: self)?.start(item2)
//        
//        let item3 = UUPItem(url: URL.init(string: ".")!, type: .IMAGE)
//        UUPManager.share(with: self)?.start(item3)
//        
//        let  item4 = UUPItem(url: URL.init(string: ".")!, type: .IMAGE)
//        UUPManager.share(with: self)?.start(item4)
//        
//         let item5 = UUPItem(url: URL.init(string: ".")!, type: .IMAGE)
//        UUPManager.share(with: self)?.start(item5)
//        
//         let item6 = UUPItem(url: URL.init(string: ".")!, type: .IMAGE)
//        UUPManager.share(with: self)?.start(item6)
//        
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.notiCallbck(_:)), name: UUPNetworkRM.UUPNetworkRMDidChangeNotification, object: nil)
//        
//        UUPManager.share(with: self)?.pause()
    }
    
    @objc func notiCallbck(_ notification:Notification) -> Void {
        print(notification.userInfo!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func touchAction(_ sender: Any) {
        let acct = UIAlertController.init(title: "选择", message: nil, preferredStyle: .actionSheet)
        acct.addAction(UIAlertAction.init(title: "相册", style: .default, handler: { (action) in
            let status = PHPhotoLibrary.authorizationStatus()
            if status != .restricted {
                let picker = UIImagePickerController.init()
                picker.sourceType = .photoLibrary
                picker.mediaTypes = [kUTTypeMovie as String]
                picker.delegate = self
                self.modalPresentationStyle = .fullScreen
                self.present(picker, animated: true, completion: nil)
                
            }
        }))
        acct.addAction(UIAlertAction.init(title: "取消", style: .default, handler: { (action) in
            
        }))
        
        self.show(acct, sender: nil)
    }
}


extension ViewController : UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let url = info[UIImagePickerControllerReferenceURL] as! URL
        picker.dismiss(animated: true) {[weak self] in
            
            let item = UUPItem(url: url, type: .VIDEO)
            UUPManager.share(with: self!)?.start(item)
            self?.mItem = item
        }
    }
}
