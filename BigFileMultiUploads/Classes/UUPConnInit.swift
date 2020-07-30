//
//  UUPConnInit.swift
//  BigFileMultiUploads
//
//  初始化文件上传通道
//  Created by 殷昭 on 2020/7/13.
//

import UIKit

//UUPConnInit
extension UUPItem{
    func initupload() -> Void {
        let urlBase = URL.init(string: "")
        guard let url = urlBase else {
            return
        }
        let request = NSMutableURLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; charset=utf-8; boundary=\(kBoundary)", forHTTPHeaderField: "Content-Type")
        let requestData = _bindInitData()
        mTask = mSession?.uploadTask(with: request as URLRequest, from: requestData, completionHandler: {[weak self] (data, reponse, error) in

            defer { self?.willChangeValue(forKey: "isReady");self?.isMReady = true;self?.didChangeValue(forKey: "isReady") }
            guard let weakSelf = self else {return}
            guard let mData = data,let result = try? JSONSerialization.jsonObject(with: mData, options:.mutableContainers) as AnyObject else {
                self?.mError = .BAD_PARAMS
                self?.initupload()
                return
            }
            UUPHeader.log(String(data: mData, encoding: .utf8) ?? "返回错误了")
            guard (result["code"] as! Int) == 0 else{
                self?.mError = .BAD_PARAMS
                self?.stop()
                return
            }
            let useful:AnyObject = result["data"] as AnyObject
            self?.mSliced = UUPSliced.init(weakSelf)
            self?.mSliced?.mJobId = (useful["job_id"] as? String) ?? ""
            self?.mSliced?.mJobSign = (useful["sign"] as? String) ?? ""
            self?.mSliced?.mPerSlicedSize = (useful["chunk_size"] as? UInt64) ?? 1
            self?.mSliced?.mTotalSliced = (useful["chunk_num"] as? UInt) ?? 1
            self?.start()
        })
        mTask?.resume()
    }
    
    func _bindInitData() -> Data? {
        var bodyDic = Dictionary<String, String>.init()
        bodyDic["auth-sign"] = mConfig?.authSign
        bodyDic["channel"] = "vgc"
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
