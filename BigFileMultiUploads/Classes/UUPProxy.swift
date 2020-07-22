//
//  UUPProxy.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/10.
//

import UIKit
import Foundation

class UUPProxy: NSProxy {
    unowned var target:AnyObject?
    
    @available(*,unavailable)
    init() {
        fatalError("init unavailable")
    }
    
    class func proxyWithTarget(_ obj:AnyObject?) -> AnyObject{
        let instance = UUPProxy.alloc()
        instance.target = obj
        return instance
    }
    
    func method(for aSelector: Selector!) -> IMP!{
        return self.target?.method(for: aSelector)
    }
    
    override func responds(to aSelector: Selector) -> Bool {
        return target?.responds(to: aSelector) ?? false
    }
    
    deinit {
        UUPHeader.log("UUPProxy_deinit")
    }
}
