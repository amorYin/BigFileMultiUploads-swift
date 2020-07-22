//
//  UUPNetworkRM.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/10.
//

import UIKit
import SystemConfiguration


public class UUPNetworkRM: NSObject {
    
    public enum UUPNetworkRStatus: Int{
        case UUPNetworkRStatusUnknown          = -1
        case UUPNetworkRStatusNotReachable     = 0
        case UUPNetworkRStatusReachableViaWWAN = 1
        case UUPNetworkRStatusReachableViaWiFi = 2
    }
    
    typealias UUPNetworkRStatusBlock = @convention(swift)(UUPNetworkRStatus)->()
    
    /** UUPNetworkRM的返回通知的 KEY **/
    public static let UUPNetworkRMDidChangeNotification:Notification.Name = Notification.Name(rawValue: "UUPNetworkRMDidChangeNotification")

    /** UUPNetworkRM的返回通知的info中包含这个字段的值为 UUPNetworkRStatus **/
    public static let UUPNetworkRMNotificationStatusItem = "UUPNetworkRMNotificationStatusItem"
    
    public class var `default`:UUPNetworkRM? { get{return manager()} }
    
    private(set) var networkReachabilityStatus: UUPNetworkRStatus = .UUPNetworkRStatusUnknown
    private(set) var networkReachability:SCNetworkReachability?
    private(set) var networkReachabilityStatusBlock:UUPNetworkRStatusBlock?
    private(set) var isStarting:Bool = false
    
    public var isReachable: Bool {
        get{
            return isReachableViaWWAN || isReachableViaWiFi
        }
    }
    public var isReachableViaWWAN:Bool {
        get{
            return networkReachabilityStatus == .UUPNetworkRStatusReachableViaWWAN
        }
    }
    public var isReachableViaWiFi:Bool{
        get{
            return networkReachabilityStatus == .UUPNetworkRStatusReachableViaWiFi
        }
    }
    
    public class func manager(_ domain:String? = nil,_ address:UnsafePointer<sockaddr>? = nil) -> UUPNetworkRM?{
        guard domain == nil else{
            let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, domain!)
            return UUPNetworkRM.init(reachability)
        }
        
        guard address == nil else {
            let reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, address!)
            return UUPNetworkRM.init(reachability)
        }
        
        var rout:UnsafeMutablePointer<sockaddr>?
        if #available(iOS 9.0, *) {
            var rin = sockaddr_in6()
            rin.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
            rin.sin6_family = sa_family_t(AF_INET6)
            withUnsafeMutablePointer(to: &rin) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { st in
                    rout = st
                }
            }
        } else {
            var rin = sockaddr_in()
            rin.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            rin.sin_family = sa_family_t(AF_INET)
            withUnsafeMutablePointer(to: &rin) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { st in
                    rout = st
                }
            }
        }
        let reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, rout!)
        return UUPNetworkRM.init(reachability)
    }
    
    private override init() {super.init()}
    
    private convenience init(_ reachability:SCNetworkReachability?){
        self.init()
        networkReachability = reachability
        networkReachabilityStatus = .UUPNetworkRStatusUnknown
        UUPHeader.log("UUPNetworkRM_init")
    }
    
    public func startMonitoring() -> Void {
        stopMonitoring()
        guard networkReachability != nil else{
            return;
        }
        isStarting = true
        UUPHeader.log("UUPNetworkRM_start_noti")
        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let reachability = networkReachability, SCNetworkReachabilitySetCallback(reachability, { (target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) in
            guard let currentInfo = info else {
                UUPNetworkRM.UUPostReachabilityStatusChange(flags,nil)
                return
            }
            let infoObject = Unmanaged<UUPNetworkRM>.fromOpaque(currentInfo).takeUnretainedValue()
            UUPNetworkRM.UUPostReachabilityStatusChange(flags,infoObject.networkReachabilityStatusBlock)
        }, &context) == true else { return }
        
        guard SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue) == true else { return }
        
        DispatchQueue.global(qos: .background).async {
            var flags = SCNetworkReachabilityFlags(rawValue: 0)
            if SCNetworkReachabilityGetFlags(self.networkReachability!, &flags) {
                UUPNetworkRM.UUPostReachabilityStatusChange(flags,self.networkReachabilityStatusBlock)
            }
        }
    }
    
    public func stopMonitoring() -> Void {
        guard networkReachability != nil,isStarting else {
            return
        }
        isStarting = false
        UUPHeader.log("UUPNetworkRM_stop_noti")
        SCNetworkReachabilityUnscheduleFromRunLoop(networkReachability!, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }
    
    public func setHandleChangeBlock(_ block:@escaping (UUPNetworkRStatus)->()) -> Void {
        self.networkReachabilityStatusBlock = block
    }
    
    deinit {
        stopMonitoring()
        networkReachability = nil
        UUPHeader.log("UUPNetworkRM_deinit")
    }
}

extension UUPNetworkRM {
    private class func UUPNetworkRStatusForFlags(_ flags:SCNetworkReachabilityFlags) -> UUPNetworkRStatus{
        let isReachable = (flags == .reachable)
        let needsConnection = (flags == .connectionRequired)
        let canConnectionAutomatically = ((flags == .connectionOnDemand) || (flags == .connectionOnTraffic))
        let canConnectWithoutUserInteraction = (canConnectionAutomatically && flags == .connectionRequired)
        let isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction))
        
        if !isNetworkReachable {
            return .UUPNetworkRStatusNotReachable
        }else if flags == .isWWAN {
            return .UUPNetworkRStatusReachableViaWWAN
        }else{
            return .UUPNetworkRStatusReachableViaWiFi
        }
    }
    
    private static func UUPostReachabilityStatusChange(_ flags:SCNetworkReachabilityFlags,_ block:UUPNetworkRStatusBlock?) -> Void {
        let status:UUPNetworkRStatus = UUPNetworkRM.UUPNetworkRStatusForFlags(flags);
        if block != nil {
            block!(status)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: UUPNetworkRMDidChangeNotification, object: nil,userInfo: [UUPNetworkRMNotificationStatusItem:status])
        }
    }
}
