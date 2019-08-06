//
//  LSRemoteConfig.swift
//  wherewego
//
//  Created by 영준 이 on 05/08/2019.
//  Copyright © 2019 leesam. All rights reserved.
//

import UIKit
import FirebaseRemoteConfig

class LSRemoteConfig: NSObject {
    class ConfigNames{
        static let theme = "theme";
    }
    
    static let shared = LSRemoteConfig();
    
    var isServerAlive : Bool = true;
    lazy var firebaseConfig = RemoteConfig.remoteConfig();
    
    var theme : LSThemeManager.Theme{
        return LSThemeManager.Theme(rawValue: self.firebaseConfig.configValue(forKey: ConfigNames.theme).stringValue ?? "") ?? .summer;
    }
    
    override init() {
        super.init();
        self.firebaseConfig.setDefaults([ConfigNames.theme : "summer" as NSObject]);
    }
    
    func fetch(_ timeout: TimeInterval = 3.0, completion: @escaping (LSRemoteConfig, Error?) -> Void){
        //SWToast.activity("버전 정보 확인 중");
        /*self.firebaseConfig.fetchAndActivate { [unowned self](status, error) in
         SWToast.hideActivity();
         completion(self, error);
         }*/
        self.firebaseConfig.fetch(withExpirationDuration: timeout) { (status, error_fetch) in
            guard let rcerror = error_fetch else{
                self.firebaseConfig.activate(completionHandler: { (error_act) in
                    //SWToast.hideActivity();
                    completion(self, error_act);
                });
                return;
            }
            
            //SWToast.hideActivity();
            completion(self, rcerror);
        }
    }
}
