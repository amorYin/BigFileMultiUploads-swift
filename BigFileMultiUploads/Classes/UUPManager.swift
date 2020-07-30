//
//  UUPManager.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/9.
//

import UIKit

public class UUPManager: NSObject {
    
    private static  var mInstance:UUPManager?
    private var mDelegate:UUPItfProxy?
    private var mConfig:UUPConfig?
    private var mUploading:OperationQueue?
    private var mLivesRecord:[UUPItem]?
    private var mRMmanager:UUPNetworkRM?
    private var isForeground:Bool = true
    private var isPause:Bool = false
    private var isNetReachable:Bool = true
    
    // 初始化 编译的过程的四个安全检查
    // 1. 在调用父类初始化之前 必须给子类特有的属性设置初始值, 只有在类的所有存储属性状态都明确后, 这个对象才能被初始化
    // 2. 先调用父类的初始化方法,  再 给从父类那继承来的属性初始化值, 不然这些属性值 会被父类的初始化方法覆盖
    // 3. convenience 必须先调用 designated 初始化方法, 再 给属性初始值. 不然设置的属性初始值会被 designated 初始化方法覆盖
    // 4. 在第一阶段完成之前, 不能调用实类方法, 不能读取属性值, 不能引用self
    private override init() {
        mUploading = OperationQueue.init()
        mRMmanager = UUPNetworkRM.default
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.netStateNoti(_:)),
                                               name: UUPNetworkRM.UUPNetworkRMDidChangeNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.resignActivieNoti(_:)),
                                               name: .UIApplicationWillResignActive,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.becomeActivieNoti(_:)),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        mRMmanager!.startMonitoring()
        UUPHeader.log("UUPManager_init")
    }
    
    @objc public class func share(with obj:UUPItf) -> UUPManager?{
        guard let instance = mInstance else{
            UUPHeader.log("UUPManager_before_init")
            mInstance = UUPManager()
            mInstance?.mDelegate = UUPItfProxy.proxy(obj)
            return mInstance
        }
        UUPHeader.log("UUPManager_get_init")
        instance.mDelegate = UUPItfProxy.proxy(obj)
        instance.mConfig = instance.mDelegate?.onConfigure()
        return instance
    }
    
    @objc public class func destroy() -> Void {
        UUPHeader.log("UUPManager_destroy")
        guard let instance = UUPManager.mInstance else{return}
        guard let rm = instance.mRMmanager else {
            instance.mDelegate = nil
            UUPManager.mInstance = nil
            return
        }
        rm.stopMonitoring()
        instance.mDelegate = nil
        UUPManager.mInstance = nil
    }
    
    deinit {
        defer { UUPHeader.log("UUPManager_deinit") }
        NotificationCenter.default.removeObserver(self, name: UUPNetworkRM.UUPNetworkRMDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        mRMmanager = nil
        mConfig = nil
        if mLivesRecord != nil {
            mLivesRecord?.removeAll()
            mLivesRecord = nil
        }
        UUPConfig.destory()
        UUPUtil.removeSlicedFile()
        guard let queue = mUploading else {return}
        for (_,s) in queue.operations.enumerated() {
            s.cancel()
        }
        queue.cancelAllOperations()
        mUploading = nil
    }
    
    @objc public func start(_ obj:UUPItem,immediately immd:Bool = false) -> Void {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if (mUploading?.operations.index(of: obj)) != nil {
            obj.queuePriority = immd ? .high : .normal
            mUploading?.addOperation(obj)
            obj.start(with: self)
        }else{
            obj.queuePriority = immd ? .high : .normal
            obj.start(with: self)
        }
        guard let mr = mLivesRecord else {
            mLivesRecord = [UUPItem]()
            mLivesRecord?.append(obj)
            return
        }
        
        if !mr.contains(obj) { mLivesRecord?.append(obj) }
    }
    
    @objc public func pause() -> Void {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if !isPause {
            isPause = true
            UUPHeader.log("UUPManager_pause")
            guard let queue = mUploading else {return}
            queue.isSuspended = true
            for (_,s) in queue.operations.enumerated() {
                UUPHeader.log("UUPManager_pause:\(s)")
                if !s.isFinished {
                    guard let item:UUPItem = s as? UUPItem else {
                        s.cancel()
                        break
                    }
                    item.isAppPause = true
                }
            }
            
            guard let mr = mLivesRecord else { return }
            for (_,s) in mr.enumerated(){
                UUPHeader.log("UUPManager_pause:\(s)")
                if !s.isFinished {
                    s.isAppPause = true
                }
            }
        }
    }
    
    @objc public func resume() -> Void {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if isPause {
            if isForeground && isNetReachable {
                isPause = false
                UUPHeader.log("UUPManager_reume")
                guard let queue = mUploading else {return}
                for (_,s) in queue.operations.enumerated() {
                    guard let item:UUPItem = s as? UUPItem else {
                        s.start()
                        return
                    }
                    if !s.isFinished {
                        item.isAppPause = false
                    }
                }
                guard let mr = mLivesRecord else { return }
                for (_,s) in mr.enumerated(){
                    UUPHeader.log("UUPManager_reume:\(s)")
                    if !s.isFinished  {
                        s.isAppPause = false
                    }
                }
                queue.isSuspended = false
            }
        }
    }
    
    @objc public func cancel() -> Void {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard let queue = mUploading else {return}
        for (_,s) in queue.operations.enumerated() {
            if !s.isCancelled || !s.isFinished {
                s.cancel()
            }
        }
    }
}

extension UUPManager: UUPItfProxyy{
    func onUPPause(item: UUPItem) {
        guard let delegate = mDelegate else{return}
        delegate.onUPPause(item: item)
    }
    
    func onUPError(item: UUPItem) {
        guard let delegate = mDelegate else{return}
        delegate.onUPError(item: item)
    }
    
    func onConfigure() -> UUPConfig {
        guard let delegate = mDelegate else{return UUPConfig.default}
        return delegate.onConfigure()
    }
    
    func onUPStart(item: UUPItem) {
        guard let delegate = mDelegate else{return}
        delegate.onUPStart(item: item)
    }
    
    func onUPProgress(item: UUPItem) {
        guard let delegate = mDelegate else{return}
        delegate.onUPProgress(item: item)
    }
    
    func onUPFinish(item: UUPItem) {
        guard let delegate = mDelegate else{return}
        delegate.onUPFinish(item: item)
        guard let mr = mLivesRecord else { return }
        for (_,s) in mr.enumerated(){
            if s == item {
                guard let x = mLivesRecord?.index(of: s) else { return }
                mLivesRecord?.remove(at: x)
                return
            }
        }
    }
    
    func onUPCancel(item: UUPItem) {
        guard let delegate = mDelegate else{return}
        delegate.onUPCancel(item: item)
    }
}

extension UUPManager{
    @objc func netStateNoti(_ noti:Notification){
        guard let info = noti.userInfo,
            let statue = info[UUPNetworkRM.UUPNetworkRMNotificationStatusItem]
            else{return}
        switch statue as! UUPNetworkRM.UUPNetworkRStatus{
        case .UUPNetworkRStatusNotReachable:
            isNetReachable = false
            break
        default:
            isNetReachable = true
            break
        }
        if isNetReachable{ resume() }
        else{ pause() }
    }
    
    @objc func becomeActivieNoti(_ noti:Notification){
        isForeground = true
        if isPause { resume() }
    }
    
    @objc func resignActivieNoti(_ noti:Notification){
        isForeground = false
        if !isPause { pause() }
    }
}
