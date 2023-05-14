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
        static let VisitKorea = URL(string: "https://apis.data.go.kr/B551011")!;
    }
    
    class RestURL{
        static func VisitKorea(_ locale : Locale = Locale.current) -> URL{
            var value : URL = Hosts.VisitKorea
            
            if locale.isKorean{
                value.appendPathComponent("KorService1");
            }else if locale.isChineseTraditional{
                value.appendPathComponent("ChtService1");
            }
            else if locale.isChineseSimple{
                value.appendPathComponent("ChsService1");
            }
            else if locale.isGerman{
                value.appendPathComponent("GerService1");
            }
            else if locale.isJapanease{
                value.appendPathComponent("JpnService1");
            }
            else if locale.isSpanish{
                value.appendPathComponent("SpnService1");
            }
            else if locale.isFrench{
                value.appendPathComponent("FreService1");
            }
            else if locale.isRussian{
                value.appendPathComponent("RusService1");
            }
            else{
                value.appendPathComponent("EngService1");
            }
            
            return value;
        }
    }
    
    
}
