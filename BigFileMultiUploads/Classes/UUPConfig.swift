//
//  UUPConfig.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/9.
//

import UIKit

public class UUPConfig: NSObject {
    
    /** 同时上传线程 默认3 **/
    @objc public var maxLive:UInt
    /** 上传文件最大限制（字节B）默认2GB **/
    @objc public var maxSize:UInt64
    /** 上传文件最大时长（秒s）默认7200 **/
    @objc public var maxDuration:UInt
    /** 最大缓冲分片数（默认30，建议不低于10，不高于100） **/
    @objc public var maxSliceds:UInt
    /** 每个分片占用大小（字节B）默认5M **/
    @objc public var perSlicedSize:UInt64
    /** 每个分片上传尝试次数（默认3） **/
    @objc public var retryTimes:UInt
    /** 接口认证串 **/
    @objc public var authSign:String?
    /** 设备串码 **/
    @objc public var deviceToken:String?
    
    private static var instance:UUPConfig?
    @objc public class var `default`:UUPConfig {
        get{
            guard let ins = instance else{
                instance = self.init()
                return instance!
            }
            UUPHeader.log("UUPConfig_get_init")
            return ins
        }
    }
    
    internal required override init() {
        maxSize = 2 * 1024 * 1024 * 1024
        maxLive = 3
        maxDuration = 2 * 60 * 60
        retryTimes = 3
        perSlicedSize = 5 * 1024 * 1024
        maxSliceds = 30
        super.init()
        UUPHeader.log("UUPConfig_init")
    }
    
    class func destory(){
        UUPHeader.log("UUPConfig_destory")
        guard instance != nil else{return}
        instance = nil
    }
    
    deinit {
        authSign = nil
        deviceToken = nil
        UUPHeader.log("UUPConfig_deinit")
    }
}
