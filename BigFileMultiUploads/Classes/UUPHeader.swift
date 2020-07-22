//
//  UUPHeader.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/10.
//

import UIKit

class UUPHeader: NSObject{

    class func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(items,separator: separator,terminator: terminator)
    }
    
    class func retainCount(_ items:String,_ object:Any) {
        UUPHeader.log("\(items) retain count is \(CFGetRetainCount(object as CFTypeRef))")
    }
    
    static let url_session_manager_creation_queue:DispatchQueue = DispatchQueue.init(label: "com.bigfileupload.networking.session.manager.creation")
    
    static let url_session_manager_processing_queue:DispatchQueue = DispatchQueue.init(label: "com.bigfileupload.networking.session.manager.processing")
    
    static let url_session_manager_completion_group:DispatchGroup = DispatchGroup.init()
    
    class func url_session_manager_create_task_safely(_ block:@escaping ()->()) -> Void{
        url_session_manager_creation_queue.async(group: url_session_manager_completion_group, execute: block)
    }
    
    class func url_session_manager_processing_task_safely(_ block:@escaping ()->()) -> Void{
        url_session_manager_processing_queue.async(group: url_session_manager_completion_group, execute: block)
    }
}
