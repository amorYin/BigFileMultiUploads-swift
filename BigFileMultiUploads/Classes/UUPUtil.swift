//
//  UUPUtil.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/10.
//

import UIKit
import CommonCrypto
import MobileCoreServices

class UUPUtil: NSObject {
    private static var absolutePath:String?
    
    enum CACHE_PATH : String{
        case THRUMB_FILE = "Thrumb"
        case SLICED_FILE = "Sliced"
        case TEMPED_LIST = "Tempory"
    }
    
    class  var ROOT_FILE_PATH:String {
        get {
            guard let path = absolutePath else {
                let s:String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                absolutePath = s
                return s
            }
            return path
        }
    }
    
    class func createFile(_ filePath:String?,data:Data? = nil) -> Bool {
        guard let path:String = filePath else {return false}
        let manager = FileManager.default
        guard manager.fileExists(atPath: path) else {
            var attri:URLResourceValues = URLResourceValues.init()
            attri.isExcludedFromBackup = true
            attri.isUserImmutable = true
            attri.hasHiddenExtension = true
            var url = URL.init(fileURLWithPath: path)
            try? url.setResourceValues(attri)
            
            do{
                guard let mData = data else {
                    do{
                        try manager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                        return true
                    }catch{ return false }
                }
                try mData.write(to: url,options:[.withoutOverwriting,.noFileProtection]) ; return true
            }catch{ return false }
        }; return true
    }
    
    class func removeSlicedFile() -> Void {
        let manager = FileManager.default
        try? manager.removeItem(atPath: "\(ROOT_FILE_PATH)/\(UUPUtil.CACHE_PATH.THRUMB_FILE.rawValue)")
        try? manager.removeItem(atPath: "\(ROOT_FILE_PATH)/\(UUPUtil.CACHE_PATH.SLICED_FILE.rawValue)")
        try? manager.removeItem(atPath: "\(ROOT_FILE_PATH)/\(UUPUtil.CACHE_PATH.TEMPED_LIST.rawValue)")
    }
    
    class func removeContentFile(_ contentPath:String?) -> Void{
        guard let path = contentPath else{ return }
        let manager = FileManager.default
        try? manager.removeItem(atPath: path)
    }
    
    class func getContentPath(_ directory:UUPUtil.CACHE_PATH?,name:String?) -> String{
        guard let path = name else{
            if let dir = directory {
                return "\(ROOT_FILE_PATH)/\(dir.rawValue)"
            }
            return "\(ROOT_FILE_PATH)/\(UUPUtil.CACHE_PATH.SLICED_FILE.rawValue)"
        }
        if let dir = directory {
            return "\(ROOT_FILE_PATH)/\(dir.rawValue)/\(path)"
        }
        return "\(ROOT_FILE_PATH)/\(UUPUtil.CACHE_PATH.SLICED_FILE.rawValue)/\(path)"
    }
    
    class func getRandomName(_ name:String?) -> String{
        guard let strs = name else { return "tmp" }
        let str = strs.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(strs.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate()
        return String(format: hash as String)
    }
    
    class func calculateSpeed(_ speed:Double) -> String{
        guard speed > 1024.0 else {
            return String.init(format: "%.0fB/s", speed)
        }
        let aSpeed = speed / 1024.0
        guard aSpeed > 1024.0 else {
            return String.init(format: "%.0fKB/s", aSpeed)
        }
        let bSpeed = aSpeed / 1024.0
        guard bSpeed > 1024.0 else {
            return String.init(format: "%.1fMB/s", bSpeed)
        }
        let cSpeed = bSpeed / 1024.0
        guard cSpeed > 1024.0 else {
            return String.init(format: "%.2fGB/s", cSpeed)
        }
        let dSpeed = cSpeed / 1024.0
        return String.init(format: "%.3fTB/s", dSpeed)
    }
    
    class func calculateSize(_ size:UInt64) -> String{
        guard size > 1024 else {
            return String.init(format: "%.0fB", size)
        }
        let aSpeed:Double = Double(size / 1024)
        guard aSpeed > 1024.0 else {
            return String.init(format: "%.0fKB", aSpeed)
        }
        let bSpeed = aSpeed / 1024.0
        guard bSpeed > 1024.0 else {
            return String.init(format: "%.1fMB", bSpeed)
        }
        let cSpeed = bSpeed / 1024.0
        guard cSpeed > 1024.0 else {
            return String.init(format: "%.2fGB", cSpeed)
        }
        let dSpeed = cSpeed / 1024.0
        return String.init(format: "%.3fTB", dSpeed)
    }
    
    class func getMimetype(_ file:String) -> String {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, file as CFString, nil)?.takeUnretainedValue() else {
            return "application/octet-stream"
        }
        guard let MIMEType = UTTypeCopyPreferredTagWithClass(uti,kUTTagClassMIMEType)?.takeUnretainedValue() else{
         return "application/octet-stream"
        }
        return MIMEType as String
    }
    
    deinit {
        UUPHeader.log("UUPUtil_deinit")
    }
}
