//
//  UUPSliced.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/9.
//

import UIKit

class UUPSliced: NSObject {
    var mTotalSliced:UInt
    weak var mItem:UUPItem?
    private var mFilePath:String?
    private var mTempName:String?
    private var mTempPath:String?
    private var mSlicedList:[UUPSlicedItem]
    private var mTempCount:UInt
    private var mCurrentCount:UInt
    
    internal var mJobId:String
    internal var mJobSign:String
    internal var mFileMd5:String
    internal var mPerSlicedSize:UInt64
    
    private override init() {
        mTotalSliced = 0
        mTempCount = 30
        mCurrentCount = 0
        mPerSlicedSize = 5 * 1024 * 1024
        mSlicedList = [UUPSlicedItem]()
        mJobId = ""
        mJobSign = ""
        mFileMd5 = "MD5_test"
        super.init()
    }
    
    convenience init(_ item:UUPItem) {
        self.init()
        UUPHeader.log("UUPSliced_init")
        mItem = item
        mFilePath = item.mFilePath
        guard let config = item.mConfig else{return}
        mTempCount = config.maxSliceds
        mFileMd5 = item.mFileName ?? "MD5_test"
        mPerSlicedSize = config.perSlicedSize
    }
    
    func makeSliced() -> Void{
        guard let item = mItem,let path = mFilePath else {return}
        autoreleasepool {
            
            let remainCount = mTotalSliced - mCurrentCount
            let tempCount = mTempCount < remainCount ? mTempCount : remainCount
            if tempCount == 0 { item.mError = .NONE ; return }
            
            let file:URL = URL.init(fileURLWithPath: path)
            if file.absoluteString == "." {
                item.mError = .BAD_FILE ; return
            }
            
            if  mTempPath == nil   {
                mTempName = item.mFileName
                let rpath = UUPUtil.getContentPath(.THRUMB_FILE, name: mTempName)
                if !UUPUtil.createFile(rpath, data: nil) {
                    item.mError = .BAD_FILE ; return
                }
                mTempPath = rpath
            }
            
            guard let readHandle = try? FileHandle.init(forReadingFrom: file) else{
                item.mError = .BAD_IO ; return
            }
            
            let x = item.mSize / mPerSlicedSize
            let y = item.mSize % mPerSlicedSize
            mTotalSliced = UInt(y>0 ? x+1 : x)
            let buffer = mPerSlicedSize
            let ext = file.pathExtension
            
            for i in mCurrentCount + 1 ... (mCurrentCount + tempCount) {
                readHandle.seek(toFileOffset: buffer * UInt64(i - 1) )
                let data = readHandle.readData(ofLength: Int(buffer))
                let path = "\(mTempPath!)/\(mTempName!)_\(i).\(ext)"
                _ = UUPUtil.createFile(path, data: data)
                UUPHeader.log(path)
                
                let sItem = UUPSlicedItem.init(path)
                sItem.mSlicedIndex = i
                sItem.mSlicedSize = UInt64(data.count)
                sItem.mProgress = Double(sItem.mSlicedSize) / Double(item.mSize)
                mSlicedList.append(sItem)
            }
            mCurrentCount = mCurrentCount + tempCount
            readHandle.closeFile()
        }
    }
    
    func nextSlicedItem() -> UUPSlicedItem? {
        
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if mCurrentCount < mTotalSliced {
            if mCurrentCount == 0 || mSlicedList.count == (mTempCount - 2) {
                makeSliced()
            }
        }
        if mSlicedList.isEmpty { return nil }
        
        for item in mSlicedList {
            if !item.isFinish && !item.isSuspend{
                return item
            }
        }
        return nil
    }
    
    func clean(_ item:UUPSlicedItem?) -> Void {
        
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard let tmpItem = item else { return }
        
        if tmpItem.mSlicedFile != nil {
            UUPUtil.removeContentFile(tmpItem.mSlicedFile)
        }
        
        guard let model_index = mSlicedList.index(of: tmpItem) else { return }
        mSlicedList.remove(at: model_index)
    }
    
    func destory() -> Void {
        
    }
    
    deinit {
        UUPHeader.log("UUPSliced_deinit")
        mItem = nil
    }
}
