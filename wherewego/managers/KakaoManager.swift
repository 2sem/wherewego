//
//  KakaoManager.swift
//  wherewego
//
//  Created by 영준 이 on 2023/05/16.
//  Copyright © 2023 leesam. All rights reserved.
//

import Foundation
import KakaoSDKCommon

class KakaoManager {
    static func initialize() {
        let pname = "kakao"
        let keyName = "key"
        
        guard let kakaoPlist = Bundle.main.path(forResource: pname, ofType: "plist") else{
            preconditionFailure("Please create plist file named of Where We Go. file[\(pname).plist]");
        }
        
        guard let dict = NSDictionary.init(contentsOfFile: kakaoPlist) as? [String : String] else{
            preconditionFailure("Please \(pname).plist is not Property List.");
        }
        
        guard let key = dict["key"] else {
            preconditionFailure("Please insert \(keyName) into \(pname).plist.");
        }
        
        KakaoSDK.initSDK(appKey: key)
    }
}
