//
//  UUPConnCheck.swift
//  BigFileMultiUploads
//
//  检查分片上传情况
//  Created by 殷昭 on 2020/7/13.
//

import UIKit

extension UUPConnUpload{
    
    func checkupload() -> Void {
        guard let item = mItem else {
            self.mItem?.mCurrentLives -= 1
            self.isMFinish = true
            self.mItem?.start()
            return
        }
        let urlBase = URL.init(string: "")
        guard let url = urlBase else {
            self.mItem?.mCurrentLives -= 1
            self.isMFinish = true
            self.mItem?.start()
            return
        }
        let request = NSMutableURLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; charset=utf-8; boundary=\(item.kBoundary)", forHTTPHeaderField: "Content-Type")
        let requestData = _bindCheckData()
        mTask = item.mSession?.uploadTask(with: request as URLRequest, from: requestData, completionHandler: {[weak self] (data, reponse, error) in
            guard let mData = data else {
                self?.mItem?.mError = .BAD_NET
                self?.mItem?.mCurrentLives -= 1
                self?.mItem?.start()
                self?.isMFinish = true
                return
            }
            UUPHeader.log(String(data: mData, encoding: .utf8) ?? "返回错误了")
            guard let result = try? JSONSerialization.jsonObject(with: mData, options:.mutableContainers) as AnyObject else{
                self?.mItem?.mError = .BAD_PARAMS
                self?.mItem?.mCurrentLives -= 1
                self?.mItem?.start()
                self?.isMFinish = true
                return
            }
            guard let s = result["code"],s as! Int == 0 else{
                self?.mItem?.mCurrentLives -= 1
                self?.mItem?.start()
                self?.isMFinish = true
                return
            }
            let useful:AnyObject = result["data"] as AnyObject
            guard useful["chunk_size"] as! Int > 0  else{
                self?.mItem?.mCurrentLives -= 1
                self?.mItem?.start()
                self?.isMFinish = true
                return
            }
            self?.mItem?.mPProgress += self?.mCurrentItem?.mProgress ?? 0
            self?.mCurrentItem?.isSuspend = true
            self?.mCurrentItem?.isFinish = true
            self?.mItem?.mSliced?.clean(self?.mCurrentItem)
            self?.mItem?.mCurrentLives -= 1
            self?.isMFinish = true
            self?.mItem?.start()
        })
        mTask?.resume()
    }
    
    func _bindCheckData() -> Data? {
        
        guard let item = mItem else {
            return nil
        }
        var bodyDic = Dictionary<String, String>.init()
        bodyDic["auth-sign"] = item.mConfig?.authSign
        bodyDic["channel"] = "vgc"
        bodyDic["sign"] = item.mSliced?.mJobSign
        bodyDic["job_id"] = item.mSliced?.mJobId
        bodyDic["chunks"] = "\(item.mSliced?.mTotalSliced ?? 1)"
        bodyDic["file_name"] = item.mDisplayName
        bodyDic["file_md5"] = item.mFileName
        bodyDic["file_size"] = "\(item.mSize)"
        bodyDic["file_mime_type"] = item.mMimetype
        bodyDic["Device-Token"] = item.mConfig?.deviceToken
        
        var str:String = ""
        for (_,v) in bodyDic.enumerated() {
            str = str.appendingFormat("--%@\r\n", item.kBoundary)
            str = str.appendingFormat("Content-Disposition: form-data; name=\"%@\"", v.key)
            str = str.appending("\r\n\r\n")
            str = str.appendingFormat("%@\r\n", v.value)
        }
        return str.data(using: .utf8)
    }
}

//UUPConnCheck
extension UUPItem{
    func checkupload() -> Void {
        let urlBase = URL.init(string: "https://upload.newscctv.net/ks3/v1/checkupload.php")
        guard let url = urlBase else {
            return
        }
        let request = NSMutableURLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; charset=utf-8; boundary=\(kBoundary)", forHTTPHeaderField: "Content-Type")
        let requestData = _bindCheckData()
        mTask = mSession?.uploadTask(with: request as URLRequest, from: requestData, completionHandler: {[weak self] (data, reponse, error) in
            guard let mData = data else {
                self?.mError = .BAD_NET
                self?.start()
                return
            }
            UUPHeader.log(String(data: mData, encoding: .utf8) ?? "返回错误了")
            guard let result = try? JSONSerialization.jsonObject(with: mData, options:.mutableContainers) as AnyObject else{
                self?.mError = .BAD_PARAMS
                self?.start()
                return
            }
            if let s = result["code"],s as! Int == 0 {
                self?.mPProgress += self?.mCurrentItem!.mProgress ?? 0
                self?.mCurrentItem?.isSuspend = true
                self?.mCurrentItem?.isFinish = true
                self?.mSliced?.clean(self?.mCurrentItem)
                self?.start()
            } else {
                self?.start()
            }
        })
        mTask?.resume()
    }
    
    func _bindCheckData() -> Data? {
        var bodyDic = Dictionary<String, String>.init()
        bodyDic["auth-sign"] = mConfig?.authSign
        bodyDic["channel"] = "vgc"
        bodyDic["sign"] = mSliced?.mJobSign
        bodyDic["job_id"] = mSliced?.mJobId
        bodyDic["chunks"] = "\(mSliced?.mTotalSliced ?? 1)"
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
        return str.data(using: .utf8)
    }
}

