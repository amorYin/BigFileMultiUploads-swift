//
//  UUPConnUpload.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/13.
//

import UIKit

//UUPConnUpload
extension UUPItem{
    func startupload() -> Void {
        let urlBase = URL.init(string: "上传接口")
        guard let url = urlBase else {
            return
        }
        let request = NSMutableURLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; charset=utf-8; boundary=\(kBoundary)", forHTTPHeaderField: "Content-Type")
        let requestData = _bindUploadData()
        mTask = mSession?.uploadTask(with: request as URLRequest, from: requestData, completionHandler: {[weak self] (data, reponse, error) in
            guard let mData = data else {
                self?.mCurrentItem?.isSuspend = false
                self?.mCurrentItem?.isFinish = false
                self?.checkupload()
                return
            }
            UUPHeader.log(String(data: mData, encoding: .utf8) ?? "返回错误了")
            guard let result = try? JSONSerialization.jsonObject(with: mData, options:.mutableContainers) as AnyObject else{
                self?.mCurrentItem?.isSuspend = false
                self?.mCurrentItem?.isFinish = false
                self?.checkupload()
                return
            }
            if let s = result["code"],s as! Int == 0 {
                self?.mPProgress += self?.mCurrentItem!.mProgress ?? 0
                self?.mCurrentItem?.isSuspend = true
                self?.mCurrentItem?.isFinish = true
                self?.mSliced?.clean(self?.mCurrentItem)
                
                let useful:AnyObject = result["data"] as AnyObject
                self?.mRemoteUri = useful["url"] as? String
                self?.start()
            } else {
                self?.mCurrentItem?.isSuspend = false
                self?.mCurrentItem?.isFinish = false
                self?.checkupload()
            }
        })
        mTask?.resume()
    }
    
    func _bindUploadData() -> Data? {
        var bodyDic = Dictionary<String, String>.init()
        bodyDic["auth-sign"] = mConfig?.authSign
        bodyDic["sign"] = mSliced?.mJobSign
        bodyDic["job_id"] = mSliced?.mJobId
        bodyDic["chunk"] = "\(mCurrentItem?.mSlicedIndex ?? 1)"
        bodyDic["chunks"] = "\(mSliced?.mTotalSliced ?? 1)"
        bodyDic["channel"] = "vgc"
        bodyDic["chunk_size"] = "\(mSliced?.mPerSlicedSize ?? 1)"
        bodyDic["file_name"] = mDisplayName
        bodyDic["file_md5"] = mFileName
        bodyDic["file_size"] = "\(mSize)"
        bodyDic["file_mime_type"] = mMimetype
        bodyDic["Device-Token"] = mConfig?.deviceToken
        
        var str:String = ""
        for (_,v) in bodyDic.enumerated() {
            str = str.appendingFormat("--%@\r\n", kBoundary)
            str = str.appendingFormat("Content-Disposition: form-data; name=\"%@\"", v.key)
            str = str.appending("\r\n\r\n")
            str = str.appendingFormat("%@\r\n", v.value)
        }
        
        str = str.appendingFormat("--%@\r\n", kBoundary)
        str = str.appendingFormat("Content-disposition: form-data; name=\"file\"; filename=\"%@\"", mDisplayName!)
        str = str.appending("\r\n")
        str = str.appending("Content-Type: application/octet-stream")
        str = str.appending("\r\n\r\n")

        //parms
        var data = str.data(using: .utf8)
        
        //file
        guard let urlStr = mCurrentItem?.mSlicedFile else{
            UUPHeader.log("UUPConnUpload 获取当前分片数据出错,mCurrentItem可能为nil")
            return data
        }
        let url = URL.init(fileURLWithPath: urlStr) 
        guard let fileData = try? Data.init(contentsOf: url, options: .uncachedRead) else{
            UUPHeader.log("UUPConnUpload 获取当前分片数据出错,当前分片可能不存在")
            return data
        }
        
        data?.append(fileData)
        
        //end
        data?.append("\r\n--\(kBoundary)--\r\n".data(using: .utf8)!)
        return data
    }
}

