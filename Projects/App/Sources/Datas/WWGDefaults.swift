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
        static let LastMapSpan = "LastMapSpan";
        static let LastMapSpanLongitude = "LastMapSpanLongitude";

        static let LaunchCount = "LaunchCount";

        static let AdsShownCount = "AdsShownCount";
        static let AdsTrackingRequested = "AdsTrackingRequested";

        static let FavoritePlaces = "FavoritePlaces";
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

    /// Last camera span (degrees latitude delta) the map screen settled on —
    /// nil until the first real settle, so callers can tell "never set" from
    /// "explicitly zero" and fall back accordingly (e.g. to a span derived
    /// from the legacy `Range` value).
    static var LastMapSpan : Double?{
        get{
            let value = Defaults.double(forKey: Keys.LastMapSpan);
            return value > 0 ? value : nil;
        }

        set(value){
            guard let value = value else { return; }
            Defaults.set(value, forKey: Keys.LastMapSpan);
        }
    }

    /// Longitude counterpart to `LastMapSpan` — both deltas are needed to
    /// restore the exact aspect ratio the map last settled on (a square
    /// span gets refit asymmetrically by MapKit, drifting the zoom out a
    /// little more on every relaunch). nil until the first real settle, and
    /// also nil for a pre-existing save made before this key existed — that
    /// legacy case falls back to a square span instead of losing the
    /// remembered zoom entirely.
    static var LastMapSpanLongitude : Double?{
        get{
            let value = Defaults.double(forKey: Keys.LastMapSpanLongitude);
            return value > 0 ? value : nil;
        }

        set(value){
            guard let value = value else { return; }
            Defaults.set(value, forKey: Keys.LastMapSpanLongitude);
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
    
    // ATT permission is now handled by SwiftUIAdManager.requestAppTrackingIfNeed()
}


// MARK: - Favorite Places
//
// No Codable in the data layer — favorites are persisted as a plain array of
// [String: AnyObject] dictionaries (property-list compatible) via UserDefaults,
// and rehydrated into KGDataTourInfo through its existing field-dictionary
// initializer, matching the KGDataTourObject convention used everywhere else.
extension WWGDefaults{
    // Only the fields needed to render a list row and re-open the detail screen
    // without a network round-trip are persisted.
    private static let favoriteFieldKeys : [String] = [
        KGDataTourInfo.fieldNames.id,
        KGDataTourInfo.fieldNames.type,
        KGDataTourInfo.fieldNames.title,
        KGDataTourInfo.fieldNames.thumbnail,
        KGDataTourInfo.fieldNames.image,
        KGDataTourInfo.fieldNames.primaryAddr,
        KGDataTourInfo.fieldNames.detailAddr,
        KGDataTourInfo.fieldNames.longitude,
        KGDataTourInfo.fieldNames.latitude,
    ];

    static var FavoritePlaces : [KGDataTourInfo]{
        get{
            let raw = Defaults.array(forKey: Keys.FavoritePlaces) as? [[String : Any]] ?? [];
            return raw.map { entry in
                let fields = entry.mapValues { $0 as AnyObject };
                return KGDataTourInfo(fields);
            };
        }
    }

    private static func favoriteEntry(from info : KGDataTourInfo) -> [String : AnyObject]{
        var entry : [String : AnyObject] = [:];

        for key in favoriteFieldKeys{
            if let value = info.fields[key]{
                entry[key] = value;
            }
        }

        return entry;
    }

    static func isFavorite(id : Int) -> Bool{
        return FavoritePlaces.contains { $0.id == id; };
    }

    static func addFavorite(_ info : KGDataTourInfo){
        guard let id = info.id else{ return; }

        var raw = Defaults.array(forKey: Keys.FavoritePlaces) as? [[String : Any]] ?? [];
        raw.removeAll { entry in
            let entryFields = entry.mapValues { $0 as AnyObject };
            return KGDataTourInfo(entryFields).id == id;
        };
        raw.append(favoriteEntry(from: info));

        Defaults.set(raw, forKey: Keys.FavoritePlaces);
    }

    static func removeFavorite(id : Int){
        var raw = Defaults.array(forKey: Keys.FavoritePlaces) as? [[String : Any]] ?? [];
        raw.removeAll { entry in
            let entryFields = entry.mapValues { $0 as AnyObject };
            return KGDataTourInfo(entryFields).id == id;
        };

        Defaults.set(raw, forKey: Keys.FavoritePlaces);
    }

    @discardableResult
    static func toggleFavorite(_ info : KGDataTourInfo) -> Bool{
        guard let id = info.id else{ return false; }

        if isFavorite(id: id){
            removeFavorite(id: id);
            return false;
        }else{
            addFavorite(info);
            return true;
        }
    }
}

