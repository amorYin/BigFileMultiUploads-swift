//
//  UUPItem.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/9.
//

import UIKit
import Photos

public class UUPItem: Operation {
    
    private var isAppSelfPause:Bool = false
    private var isAppSelfResume:Bool = false
    private var mmError:UUPItemErrorType = .NONE
    private var lowTimes:Int = 0
    private(set) var sendTimes:Int = 0
    internal var mSliced:UUPSliced?
    private(set) var mConfig:UUPConfig?
    private(set) var mReceiver:UUPReceiver?
    private(set) var mDelegate:UUPItfProxyy?
    private(set) var mCurrentItem:UUPSlicedItem?
    private(set) var mFileName:String?
    private(set) var mSession:URLSession?
    internal     var mTask:URLSessionTask?
    private      var mSpeedTimer:Timer?
    internal     var mPProgress:Double = 0
    internal     var mLastProgress:Int64 = 0
    
    
    private(set) var isMFinish:Bool = false
    private(set) var isMCancelled:Bool = false
    private(set) var isMPaused:Bool = false
    private(set) var isMExcuting:Bool = false
    private(set) var isMPreReady:Bool = false
    internal     var isMReady:Bool = false
    
    internal     var mMaxLives:Int = 5
    internal     var mCurrentLives:Int = 0
    internal     var mRequestList:[UUPConnUpload]
    
    internal let kBoundary:String = "----WebKitFormBoundaryXGAyMbuVkeaFc916"
    
    private override init() {
        mRequestList = [UUPConnUpload]()
        super.init()
    }
    
    func start(with delegate:UUPItfProxyy) -> Void{
        defer {
            if mSpeedStr == nil{
                mSpeedTimer = Timer.init(timeInterval: 1, target: self, selector: #selector(calculatProsess(_:)), userInfo: self, repeats: true)
                RunLoop.main.add(mSpeedTimer!, forMode: .defaultRunLoopMode)
            }
        }
        if !isReady {
            mConfig = delegate.onConfigure()
            mDelegate = delegate
            if #available(iOS 9, *) {
                configure()
            } else {
                // Fallback on earlier versions
                stop()
            }
            
        }
    }
    
    @objc public func pause() -> Void {
        willChangeValue(forKey: "isExecuting")
        defer { didChangeValue(forKey: "isExecuting") }
        isMPaused = true
        syncProsess(.RUN_PAUSE)
    }
    
    @objc public func resume() -> Void {
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isCancelled")
        defer {
            didChangeValue(forKey: "isCancelled")
            didChangeValue(forKey: "isExecuting")
        }
        isMPaused = false
        isMCancelled = false
    }
    
    func finsih() -> Void {
        willChangeValue(forKey: "isFinished")
        defer { didChangeValue(forKey: "isFinished") }
        isMFinish = true
        isUploadFinish = true
        UUPHeader.log("UUPItem_finsih")
        syncProsess(.RUN_FINISH)
        UUPUtil.removeContentFile(mFilePath)
        mSpeedTimer?.invalidate()
        mSpeedTimer = nil
    }
    
    func stop() -> Void {
        willChangeValue(forKey: "isFinished")
        willChangeValue(forKey: "isCancelled")
        defer {
            didChangeValue(forKey: "isCancelled")
            didChangeValue(forKey: "isFinished")
        }
        isMCancelled = true
        isMFinish = true
        syncProsess(.RUN_CANCEL)
        mSpeedTimer?.invalidate()
        mSpeedTimer = nil
    }
    
    public override func start() -> Void {
        if !isAppSelfPause && !isFinished && !isMPaused {
            UUPHeader.log("UUPItem_start")
            willChangeValue(forKey: "isExecuting")
            willChangeValue(forKey: "isCancelled")
            defer {
                didChangeValue(forKey: "isCancelled")
                didChangeValue(forKey: "isExecuting")
            }
            isMPaused = false
            isMCancelled = false
            
            for s in mRequestList{
                if s.isMFinish {
                    guard let model_index = mRequestList.index(of: s) else { continue }
                    mRequestList.remove(at: model_index)
                }
            }
            
            guard let item = mSliced?.nextSlicedItem() else{
                guard mRemoteUri != nil else { return }
                if(mRequestList.count < 1) {
                    finsih();
                }
                return
            }
            
            mCurrentItem = item
            while mCurrentLives < mMaxLives{
                guard let item = mSliced?.nextSlicedItem() else{
                    return
                }
                item.isSuspend = true
                let s = UUPConnUpload(a: self,i:item)
                mRequestList.append(s)
                s.startupload()
                mCurrentLives += 1;
            }
        }
    }
    
    public override func cancel() {
        willChangeValue(forKey: "isFinished")
        willChangeValue(forKey: "isCancelled")
        defer {
            didChangeValue(forKey: "isCancelled")
            didChangeValue(forKey: "isFinished")
        }
        isMCancelled = true
        isMFinish = true
        mSpeedTimer?.invalidate()
        mSpeedTimer = nil
    }
    
    @objc public override var isCancelled: Bool {
        get {
            return isMCancelled
        }
    }
    
    @objc public override var isFinished: Bool {
        get {
            return isMFinish
        }
    }
    
    @objc public override var isExecuting: Bool {
        get {
            return isMExcuting
        }
    }
    
    @objc public override var isReady: Bool {
        get {
            if isMPreReady {
                return isMReady
            }
            return isMPreReady
        }
    }
    
    /** 文件URL **/
    @objc public var mContentUri:URL?
    /** 文件名称 **/
    @objc public internal(set) var mDisplayName:String?
    /**文件的绝对路径 **/
    @objc public internal(set) var mFilePath:String?
    /** 上传文件的路径 **/
    @objc public internal(set) var mRemoteUri:String?
    /** 文件缩略图 **/
    @objc public internal(set) var mThumbnailsPath:String?
    /** 文件mime-type **/
    @objc public internal(set) var mMimetype:String?
    /** 上传速度格式化字符串 **/
    @objc public internal(set) var mSpeedStr:String?
    /** 文件大小格式化字符串 **/
    @objc public internal(set) var mSizeStr:String?
    /** 文件大小，单位字节 **/
    @objc public internal(set) var mSize:UInt64 = 0
    /** 文件时长，单位秒 **/
    @objc public internal(set) var mDuration:UInt = 0
    /** 文件上传进度 0～1.0 **/
    @objc public internal(set) var mProgress:Double = 0
    /** 当前一秒内上传大小，单位字节 **/
    @objc public internal(set) var mSpeed:Double = 0
    /** 文件约定类型 **/
    @objc public internal(set) var mType:UUPItemType = .IMAGE
    /** 错误 **/
    @objc public internal(set) var mError:UUPItemErrorType {
        set{
            mmError = newValue
            syncProsess(.RUN_ERROR)
        }
        get{
            return mmError
        }
    }
    /** 上传成功 **/
    public internal(set) var isUploadFinish:Bool?
    
    @objc public convenience init(url u:URL, type t:UUPItemType) {
        self.init()
        mContentUri = u
        mType = t
    }
    
    deinit {
        mSliced = nil
        mRequestList.removeAll()
        UUPHeader.log("UUPItem_deinit")
        if mTask != nil {
            mTask?.cancel()
        }
    }
}

extension UUPItem {
    
    var  isAppPause:Bool {
        get{
            return isAppSelfPause
        }
        set{
            isAppSelfPause = newValue
            if(!newValue){ start() }
        }
    }
    
    var isAppResume:Bool{
        get{
            return isAppSelfResume
        }
        set{
            isAppSelfResume = newValue
        }
    }
    
    @objc func calculatProsess(_ timer:Timer) -> Void{
        guard let weakSelf = timer.userInfo as? UUPItem else{
            timer.invalidate()
            return
        }
        if !isMPaused && !isAppPause {
            
            if weakSelf.mProgress == 0.0{
                weakSelf.mSpeedStr = "初始化中"
                weakSelf.lowTimes = 0
            }else if weakSelf.mProgress >= 0.9999999 {
                weakSelf.mSpeedStr = "合成中"
                weakSelf.lowTimes = 0
            }else{
                sendTimes += 1
                let tem = Double(weakSelf.mReceiver!.mTotalBytesSent - weakSelf.mLastProgress) / Double(sendTimes)
                weakSelf.mSpeed = tem
                weakSelf.mSpeedStr = UUPUtil.calculateSpeed(weakSelf.mSpeed)
                
                if weakSelf.lowTimes >= 10 {
                    weakSelf.mSpeedStr = "网速缓慢 \(weakSelf.mSpeedStr ?? "")"
                    if weakSelf.lowTimes % 10 == 0 {
                        weakSelf.mError = .LOW_NET
                    }
                }
            }
            
            if weakSelf.mSpeed < 10 {
                weakSelf.lowTimes += 1
            }else{
                weakSelf.lowTimes = 0
            }
        }else{
            sendTimes = 0
            weakSelf.mLastProgress = weakSelf.mReceiver!.mTotalBytesSent
            weakSelf.mSpeedStr = "网络缓慢 0B/s"
        }
        
        weakSelf.syncProsess(.RUN_PROSESS)
    }
    
    func syncProsess(_ type:UUPItemRunType) -> Void {
        guard let delegate = mDelegate else { return }
        switch type {
        case .RUN_START:
            delegate.onUPStart(item: self)
            break
        case .RUN_PROSESS:
            delegate.onUPProgress(item: self)
            break
        case .RUN_CANCEL:
            delegate.onUPCancel(item: self)
            break
        case .RUN_PAUSE:
            delegate.onUPPause(item: self)
            break
        case .RUN_FINISH:
            delegate.onUPFinish(item: self)
            break
        case .RUN_ERROR:
            delegate.onUPError(item: self)
            break
        default:
            break
        }
    }
}

extension UUPItem {
    
    @available(iOS 9, *)
    func configure() -> Void {
        guard let uri = mContentUri else{
            stop()
            return
        }
        
        //判断文件是否存在
        if !uri.isFileURL {
            let fetch = PHAsset .fetchAssets(withALAssetURLs: [uri], options: nil)
            guard let asset = fetch.firstObject else {
                mError = .BAD_IO
                stop()
                return
            }
            mDisplayName = (asset.value(forKey: "filename") as? String) ?? uri.lastPathComponent
            let name = UUPUtil.getRandomName(mDisplayName)
            let temppath = UUPUtil.getContentPath(.TEMPED_LIST, name: nil)
            _ = UUPUtil.createFile(temppath)
            let toURL = URL.init(fileURLWithPath: "\(temppath)/\(name).\(uri.pathExtension)")
            
            if FileManager.default.fileExists(atPath: toURL.path) {
                self.configAfter(toURL)
            }else{
                guard let resource = PHAssetResource.assetResources(for: asset).first else{
                    mError = .BAD_IO
                    stop()
                    return
                }
                
                PHAssetResourceManager.default().writeData(for: resource, toFile: toURL, options: nil) {[weak self] (error) in
                    guard error != nil else{
                        self?.configAfter(toURL)
                        return
                    }
                    self?.mError = .BAD_IO
                    self?.stop()
                    return
                }
            }
        }else {
            configAfter(mContentUri!)
        }
    }
    
    func configAfter(_ rpath:URL,_ vedio:AVAsset? = nil) -> Void {
        willChangeValue(forKey: "isMPreReady")
        defer { didChangeValue(forKey: "isMPreReady") }
        
        guard let fileAttri = try? FileManager.default.attributesOfItem(atPath: rpath.path) else {
            mError = .BAD_IO
            stop()
            return
        }
        mFilePath = rpath.path
        mThumbnailsPath = rpath.path
        mDisplayName = mDisplayName ?? mContentUri?.lastPathComponent
        mFileName = UUPUtil.getRandomName(mDisplayName)
        mMimetype = UUPUtil.getMimetype(rpath.pathExtension)
        mSize = fileAttri[.size] as! UInt64
        mSizeStr = UUPUtil.calculateSize(mSize)
        if vedio != nil {
            mDuration = UInt(lround(Double(vedio!.duration.value / Int64(vedio!.duration.timescale))))
        }
        isMPreReady = true
        syncProsess(.RUN_START)
        check()
    }
    
    func check() -> Void {
        guard mSize <= mConfig!.maxSize else{
            mError = .OVER_MAXSIZE
            stop()
            return
        }
        
        guard mDuration <= mConfig!.maxDuration else{
            mError = .OVER_MAXDURATION
            stop()
            return
        }
        
        guard mError == .NONE else {
            mError = .OVER_MAXDURATION
            stop()
            return
        }
        
        if mSession == nil {
            if mReceiver == nil { mReceiver = UUPReceiver.init(self) }
            let config = URLSessionConfiguration.default
            config.httpMaximumConnectionsPerHost = 5
            mSession = URLSession.init(configuration: config, delegate: mReceiver, delegateQueue: nil)
        }
        
        guard mSliced != nil else {
            initupload()
            return
        }
        resume()
    }
}
