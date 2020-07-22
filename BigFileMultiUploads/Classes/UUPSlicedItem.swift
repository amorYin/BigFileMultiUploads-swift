//
//  UUPSlicedItem.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/9.
//

import UIKit

class UUPSlicedItem: NSObject {
    var mSlicedFile:String?
    var mSlicedIndex:UInt
    var mSlicedSize:UInt64
    var mProgress:Double
    var mPProgress:Double
    var isFinish:Bool
    var isSuspend:Bool
    
    private override init() {
        mSlicedIndex = 0
        mSlicedSize = 0
        mProgress = 0.0
        mPProgress = 0.0
        isFinish = false
        isSuspend = false
        super.init()
    }
    
    convenience init(_ file:String) {
        self.init()
        mSlicedFile = file
    }
    
    deinit {
        UUPHeader.log("UUPSlicedItem_deinit")
    }
}
