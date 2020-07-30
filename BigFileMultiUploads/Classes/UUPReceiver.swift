//
//  UUPReceiver.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/9.
//

import UIKit

class UUPReceiver: NSObject,URLSessionTaskDelegate {
    weak var mItem:UUPItem?
    var parms:[String:Double]
    var lastProgess:Double
    var mTotalBytesSent:Int64
    private override init() {
        parms = [String:Double]()
        mTotalBytesSent = 0
        lastProgess = 0.0
        super.init()
    }
    
    convenience init(_ item:UUPItem) {
        self.init()
        UUPHeader.log("UUPReceiver_init")
        mItem = item
    }
    
    deinit {
        UUPHeader.log("UUPReceiver_deinit")
        parms.removeAll()
        mItem = nil
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    
        mTotalBytesSent += bytesSent
        
        guard let sItem = mItem,let sv = task.currentRequest?.value(forHTTPHeaderField: "current-value"),let cv = task.currentRequest?.value(forHTTPHeaderField: "current-index") else {
            return
        }
        let process = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        let base = Double(sv)! * process
        parms[cv] = base
        
        var current:Double = 0.0
        
        for (_,k) in parms.enumerated() {
            current += k.value
        }
//        current = sItem.mPProgress + current
        if current > sItem.mProgress {sItem.mProgress = current}
        
//        if process == 1.0 {
//            sItem.mPProgress += base
//            parms.removeValue(forKey: cv)
//        }
        if(current - lastProgess > 0.01){//提升性能
            sItem.syncProsess(.RUN_PROSESS)
            lastProgess = current
        }
    }
}
