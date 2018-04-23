//
//  KGDataTourResponseHeader.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 26..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class KGDataTourResponseHeader : KGDataTourObject {
    //resultCode : result code
    //resultMsg : msg for result code
    //numOfRows : max result for a row
    //pageNo : received page number
    //totalCount : total record count
    
    class fieldNames{
        static let result = "resultCode";
        static let msg = "resultMsg";
        static let count = "numOfRows";
        static let page = "pageNo";
        static let total = "totalCount";
    }
    
    var result : Int{
        get{
            return self.parseToInt(self.fields[fieldNames.result]) ?? 0;
        }
        
        set(value){
            self.fields[fieldNames.result] = value as AnyObject?;
        }
    }
    
    var msg : String?{
        get{
            return self.parseToString(self.fields[fieldNames.msg]);
        }
        
        set(value){
            self.fields[fieldNames.msg] = value as AnyObject?;
        }
    }
    
    var count : Int{
        get{
            return self.parseToInt(self.fields[fieldNames.count]) ?? 0;
        }
        
        set(value){
            self.fields[fieldNames.count] = value as AnyObject?;
        }
    }
    
    var page : Int{
        get{
            return self.parseToInt(self.fields[fieldNames.page]) ?? 0;
        }
        
        set(value){
            self.fields[fieldNames.page] = value as AnyObject?;
        }
    }
    
    var total : Int{
        get{
            return self.parseToInt(self.fields[fieldNames.total]) ?? 0;
        }
        
        set(value){
            self.fields[fieldNames.total] = value as AnyObject?;
        }
    }
    
    override init(){
        
    }
    
    init(_ json : [String : AnyObject]){
        super.init();
        self.fromJson(json);
    }
    
    override var description: String{
        return "result[\(self.result)] msg[\(self.msg ?? "")] count[\(self.count)] page[\(self.page)] total[\(self.total)]";
    }
}
