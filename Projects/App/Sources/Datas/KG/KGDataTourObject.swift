//
//  KGDataTourObject.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 26..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class KGDataTourObject : NSObject{
    var fields : [String : AnyObject] = [:];
    
    func parseToInt(_ obj : AnyObject?) -> Int?{
        var value : Int?;
        
        if let str = obj as? String{
            value = Int.init(str);
        }else if let num = obj as? NSNumber{
            value = Int(truncating: num);
        }
        
        return value;
    }
    
    func parseToFloat(_ obj : AnyObject?) -> Float?{
        var value : Float?;
        
        if let str = obj as? String{
            value = Float.init(str);
        }else if let num = obj as? NSNumber{
            value = Float.init(truncating: num);
        }
        
        return value;
    }
    
    func parseToString(_ obj : AnyObject?) -> String?{
        var value : String?;
        
        if let num = obj as? NSNumber{
            value = num.description;
        }else if let str = obj as? String{
            value = str;
        }
        
        return value;
    }
    
    func parseToDate(_ obj : AnyObject?) -> Date?{
        var value : Date?;
        let format = "yyyyMMddHHmmss";
        
        if let num = obj as? NSNumber{
            //            value = Date(timeIntervalSince1970: TimeInterval(num));
            var nums : [Int] = [];
            
            var remain = Int(truncating: num);
            var temp = remain;
            
            for _ in 1...5{
                temp = remain;
                remain = remain / 100;
                nums.append(temp - (remain * 100));
                
                if remain <= 0{
                    break;
                }
            }
            nums.append(remain);
            
            var str = "";
            for num in nums{
                str = "".appendingFormat("%02d", num) + str;
            }
            
            value = str.toDate(format);
        }else if let str = obj as? String{
            //var num = Int(str);
            //20040225000000
            value = str.toDate("yyyyMMddHHmmss") as Date?;
        }else if let date = obj as? Date{
            value = date;
        }
        
        return value;
    }
    
    func parseToUrl(_ obj : AnyObject?) -> URL?{
        var value : URL?;
        
        if let url = obj as? URL{
            value = url;
        }else if let str = obj as? String{
            value = URL(string: str);
        }
        
        return value;
    }
    
    func fromJson(_ json : [String : AnyObject]){
        
        //    print("fromJson - \(info)");
        //print("has id setter - \(self.responds(to: Selector.init("setContentId:")))");
        //print("has id getter - \(self.responds(to: Selector.init("contentId")))");
        //    self.perform(Selector("contentId"), with: 0);
        //    info?.setValue("1234", forKey: "contentId");
        
        self.fields = json;
    }
}
