//
//  UUPItf.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/10.
//

import UIKit

internal protocol UUPItfProxyy{
    func onUPStart(item:UUPItem);
    func onUPProgress(item:UUPItem);
    func onUPFinish(item:UUPItem);
    func onUPCancel(item:UUPItem);
    func onConfigure() -> UUPConfig;
    func onUPPause(item:UUPItem);
    func onUPError(item:UUPItem);
}

internal class UUPItfProxy :NSObject,UUPItfProxyy{
    private unowned var mDelegate:UUPItf?
    
    private override init() {
        
    }
    
    class func proxy(_ obj:UUPItf?) -> UUPItfProxy {
        let instance:UUPItfProxy = UUPItfProxy()
        instance.mDelegate = obj;
        return instance
    }
    
    @objc func onUPPause(item: UUPItem) {
        if self.mDelegate != nil {
            self.mDelegate?.onUPPause?(item)
//            if self.mDelegate!.responds(to:  #selector(onUPPause)) {
//                self.mDelegate!.perform( #selector(onUPPause), with: item)
//            }
        }
    }
    
    @objc func onUPError(item: UUPItem) {
        if self.mDelegate != nil {
            self.mDelegate?.onUPError?(item)
//            if self.mDelegate!.responds(to: #selector(onUPError(item:))){
//                self.mDelegate!.perform(#selector(onUPError(item:)), with: item)
//            }
        }
    }
    
    @objc func onConfigure() -> UUPConfig {
        if self.mDelegate != nil {
//            if self.mDelegate!.responds(to: #selector(onConfigure)) {
//                guard let s = self.mDelegate!.perform( #selector(onConfigure)) else {
//                    return UUPConfig.default
//                }
//                return s.takeUnretainedValue() as! UUPConfig
//            }
            return self.mDelegate!.onConfigure()
        }
        return UUPConfig.default
    }
    
    @objc func onUPStart(item: UUPItem) {
        if self.mDelegate != nil {
            self.mDelegate!.onUPStart(item)
//            if self.mDelegate!.responds(to: #selector(onUPStart(_ :))) {
//                UUPHeader.log("UUPItfProxy_onUPStart_end")
//                self.mDelegate!.perform( #selector(onUPStart(_ item:)), with: item)
//            }
        }
    }
    
    @objc func onUPProgress(item: UUPItem) {
        if self.mDelegate != nil {
            self.mDelegate!.onUPProgress(item)
//            if self.mDelegate!.responds(to:  #selector(onUPProgress(_:))) {
//                self.mDelegate!.perform( #selector(onUPProgress(_:)), with: item)
//            }
        }
    }
    
    @objc func onUPFinish(item: UUPItem) {
        if self.mDelegate != nil {
            self.mDelegate!.onUPFinish(item)
//            if self.mDelegate!.responds(to:  #selector(onUPFinish(item:))) {
//                self.mDelegate!.perform( #selector(onUPFinish(item:)), with: item)
//            }
        }
    }
    
    @objc func onUPCancel(item: UUPItem) {
        if self.mDelegate != nil {
            self.mDelegate!.onUPCancel(item)
//            if self.mDelegate!.responds(to:  #selector(onUPCancel(item:))) {
//                self.mDelegate!.perform( #selector(onUPCancel(item:)), with: item)
//            }
        }
    }
    
    deinit {
        UUPHeader.log("UUPItf_deinit")
        mDelegate = nil
    }
}
