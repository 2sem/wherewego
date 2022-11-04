//
//  KGDataManager.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 13..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreLocation
import LSExtensions

class KGDataAPI : NSObject{
    class Hosts{
        /** 
            tour 30
        */
        static let VisitKorea = URL(string: "http://apis.data.go.kr/B551011")!;
    }
    
    class RestURL{
        static func VisitKorea(_ locale : Locale = Locale.current) -> URL{
            var value : URL = Hosts.VisitKorea
            
            if locale.isKorean{
                value.appendPathComponent("KorService");
            }else if locale.isChineseTraditional{
                value.appendPathComponent("ChtService");
            }
            else if locale.isChineseSimple{
                value.appendPathComponent("ChsService");
            }
            else if locale.isGerman{
                value.appendPathComponent("GerService");
            }
            else if locale.isJapanease{
                value.appendPathComponent("JpnService");
            }
            else if locale.isSpanish{
                value.appendPathComponent("SpnService");
            }
            else if locale.isFrench{
                value.appendPathComponent("FreService");
            }
            else if locale.isRussian{
                value.appendPathComponent("RusService");
            }
            else{
                value.appendPathComponent("EngService");
            }
            
            return value;
        }
    }
    
    
}
