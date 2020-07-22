//
//  UUPItemType.swift
//  BigFileMultiUploads
//
//  Created by 殷昭 on 2020/7/10.
//

import UIKit

@objc public enum UUPItemType : Int{
    case VIDEO  = 1
    case AUDIO  = 2
    case IMAGE  = 3
}

@objc public enum UUPItemRunType : Int{
    case RUN_NONE       = 1
    case RUN_WAIT       = 2
    case RUN_START      = 3
    case RUN_PAUSE      = 4
    case RUN_PROSESS    = 5
    case RUN_FINISH     = 6
    case RUN_CANCEL     = 7
    case RUN_ERROR      = 8
};

@objc public enum UUPItemErrorType : Int{
    case NONE                    = 0//无错误
    case BAD_UPLOAD              = 103//上传失败
    case BAD_ACCESS              = 1000//需要重新登录
    case BAD_PARAMS              = 1001//参数错误
    case BAD_FUID                = 1002//fuid不存在
    case BAD_SLICED              = 1003//分片上传失败
    case BAD_MIMETYPE            = 1004//不支持的文件类型
    case BAD_OTHER               = 1005//未知服务器错误
    case BAD_MERGE               = 1006//服务端合成文件失败
    case OVER_RETRY              = 1101//超过重试次数
    case OVER_MAXSIZE            = 1102//超过大小
    case OVER_MAXDURATION        = 1103//超过时长
    case SLICED_FAIL             = 1104//分片失败
    case LOW_NET                 = 1105//网络缓慢,连续10秒网速低于10KB/s
    case BAD_NET                 = 1106//网络不通
    case BAD_FILE                = 1107//目标文件不存在
    case BAD_IO                  = 1108//读写目标文件失败
    case SLICED_IO               = 1109//读取分片失败
    
    public var description: String {
        switch self {
        case .BAD_UPLOAD:
            return "上传失败"
        case .BAD_ACCESS:
            return "需要重新登录"
        case .BAD_PARAMS:
            return "分片参数错误"
        case .BAD_FUID:
            return "分片fuid错误"
        case .BAD_SLICED:
            return "分片上传错误"
        case .BAD_MIMETYPE:
            return "不支持的文件类型"
        case .BAD_OTHER:
            return "未知错误"
        case .BAD_MERGE:
            return "文件合成失败"
        case .OVER_RETRY:
            return "超过重试次数"
        case .OVER_MAXSIZE:
            return "超过文件大小限制"
        case .OVER_MAXDURATION:
            return "超过文件时长限制"
        case .SLICED_FAIL:
            return "文件分片错误"
        case .LOW_NET:
            return "网络缓慢"
        case .BAD_NET:
            return "服务器连接失败"
        case .BAD_FILE:
            return "目标文件不存在"
        case .BAD_IO:
            return "目标文件读写失败"
        case .SLICED_IO:
            return "分片文件读写失败"
        default:
            return ""
        }
    }
};

