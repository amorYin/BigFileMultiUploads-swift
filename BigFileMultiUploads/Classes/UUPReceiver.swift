//
//  UUPReceiver.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/9.
//

import UIKit

class UUPReceiver: NSObject,URLSessionTaskDelegate {
    weak var mItem:UUPItem?
    private override init() {
        super.init()
    }
    
    convenience init(_ item:UUPItem) {
        self.init()
        UUPHeader.log("UUPReceiver_init")
        mItem = item
    }
    
    deinit {
        UUPHeader.log("UUPReceiver_deinit")
        mItem = nil
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let process = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        guard let sItem = mItem,let item = sItem.mCurrentItem else {
            return
        }
        item.mPProgress = process * item.mProgress
        sItem.mProgress = sItem.mPProgress + item.mPProgress
        sItem.syncProsess(.RUN_PROSESS)
    }
}
