//
//  WWGDefaults.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 5. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import StringLogger

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
        static let LastOpeningAdPrepared = "LastOpeningAdPrepared";

        static let Range = "Range";
        
        static let LaunchCount = "LaunchCount";

        static let AdsShownCount = "AdsShownCount";
        static let AdsTrackingRequested = "AdsTrackingRequested";
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
    
    static var LastOpeningAdPrepared : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastOpeningAdPrepared);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastOpeningAdPrepared);
        }
    }
    
    static func increaseLaunchCount(){
        self.LaunchCount = self.LaunchCount.advanced(by: 1);
    }
    
    static var LaunchCount : Int{
        get{
            //UIApplication.shared.version
            return Defaults.integer(forKey: Keys.LaunchCount);
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.LaunchCount);
        }
    }
}


extension WWGDefaults{
    static var AdsShownCount : Int{
        get{
            return Defaults.integer(forKey: Keys.AdsShownCount);
        }
        
        set{
            Defaults.set(newValue, forKey: Keys.AdsShownCount);
        }
    }
    
    static func increateAdsShownCount(){
        guard AdsShownCount < 3 else {
            return
        }
        
        AdsShownCount += 1;
        "Ads Shown Count[\(AdsShownCount)]".debug();
    }
    
    static var AdsTrackingRequested : Bool{
        get{
            return Defaults.bool(forKey: Keys.AdsTrackingRequested);
        }
        
        set{
            Defaults.set(newValue, forKey: Keys.AdsTrackingRequested);
        }
    }
    
    static func requestAppTrackingIfNeed() -> Bool{
        guard !AdsTrackingRequested else{
            return false;
        }
        
        guard AdsShownCount >= 3 else{
            AdsShownCount += 1;
            return false;
        }
        
        guard #available(iOS 14.0, *) else{
            return false;
        }
        
        AppDelegate.sharedGADManager?.requestPermission(completion: { (result) in
            AdsTrackingRequested = true;
        })
        
        return true;
    }
}

