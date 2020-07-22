//
//  UUPItf.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/10.
//

import UIKit

@objc public protocol UUPItf where Self : NSObject{
    /** 建议在 start 方法里添加对象到界面 **/
    @objc func onUPStart(_ item:UUPItem);
    @objc func onUPProgress(_ item:UUPItem);
    @objc func onUPFinish(_ item:UUPItem);
    /** 建议在 cancel 方法中获取任务中断信号移除界面 **/
    @objc func onUPCancel(_ item:UUPItem);
    @objc func onConfigure() -> UUPConfig;
    @objc optional func onUPError(_ item:UUPItem);
    @objc optional func onUPPause(_ item:UUPItem);
}

extension UUPItf{
    /** opital method **/
    public func onUPPause(_ item:UUPItem){};
    public func onUPError(_ item:UUPItem){};
}
