//
//  WWGDefaults.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 5. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class WWGDefaults{
    static var Defaults : UserDefaults{
        get{
            return UserDefaults.standard;
        }
    }
    
    class Keys{
        static let LastFullADShown = "LastFullADShown";
        static let LastShareShown = "LastShareShown";
        static let LastRewardADShown = "LastRewardADShown";
        static let LastReviewRequest = "LastReviewRequest";

        static let Range = "Range";
    }
    
    static var LastFullADShown : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastFullADShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastFullADShown);
        }
    }

    static var LastShareShown : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastShareShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastShareShown);
        }
    }
    
    static var LastRewardADShown : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastRewardADShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastRewardADShown);
        }
    }
    
    static var LastReviewRequest : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastReviewRequest);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastReviewRequest);
        }
    }
    
    static var Range : Int{
        get{
            var value = Defaults.integer(forKey: Keys.Range);
            
            if value <= 0{
                value = 1000 * 3;
            }
            
            return value;
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.Range);
        }
    }
}
