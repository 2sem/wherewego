//
//  KGDataTourRequest.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 4. 6..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class KGDataTourRequest : NSObject {
    static let plistName = "KGData";
    var serviceKey : String{
        guard let plist = Bundle.main.path(forResource: type(of: self).plistName, ofType: "plist") else{
            preconditionFailure("Please create plist file named of Where We Go. file[\(type(of: self).plistName).plist]");
        }
        
        guard let dict = NSDictionary.init(contentsOfFile: plist) as? [String : String] else{
            preconditionFailure("Please \(type(of: self).plistName).plist is not Property List.");
        }
        
        return dict["ServiceKey"] ?? "";
    }
    
    var mobileOS = "IOS";
    var mobileApp = "wherewego";

    var queries : [URLQueryItem] = [];
    
    override init() {
        self.queries.append(URLQueryItem(name: "MobileOS", value: self.mobileOS));
        self.queries.append(URLQueryItem(name: "MobileApp", value: self.mobileApp));
    }
}
