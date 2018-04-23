//
//  CLLocationCoordinate2D+.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 5. 23..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

extension CLLocationCoordinate2D{
    func isEqual(_ value : CLLocationCoordinate2D?) -> Bool{
        return self.latitude == value?.latitude && self.longitude == value?.longitude;
    }
    
    func urlForGoogleRoute(startName: String, end: CLLocationCoordinate2D, endName: String) -> URL{
        var url = URL(string:"http://map.daum.net")!;
        //let urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: true);
        
        //var url = URL(string: "http://map.daum.net/?sX=\(self.location!.latitude)&sY=\(self.location!.longitude)&sName=\("Current Location".localized())&eX=\(self.info.location!.latitude)&eY=\(self.info.location!.longitude)&eName=\(self.info.title)");
        //open url http://map.daum.net?sX=37.5199176930241
        //                            &sY=126.88215125364
        //                            &sName=Current%20Location
        //                            &eX=37.5162467956543
        //                            &eY=126.889793395996
        //                            &eName=%EC%98%81%EC%9D%BC%EB%B6%84%EC%8B%9D
        //12632.09061058575
        //8801.892062560384
        
        //if use korea?
        print("locale \(Locale.current.identifier)")
        if Locale.current.isKorean {
            //korea?
            /*urlComponents?.queryItems = [URLQueryItem(name: "sX", value: "\(self.location!.latitude * 12632.09061058575)"),
             URLQueryItem(name: "sY", value: "\(self.location!.longitude * 8801.892062560384)"),
             URLQueryItem(name: "sName", value: "Current Location"),
             URLQueryItem(name: "eX", value: "\(self.info.location!.latitude * 12632.09061058575)"),
             URLQueryItem(name: "eY", value: "\(self.info.location!.longitude * 8801.892062560384)"),
             URLQueryItem(name: "eName", value: self.info.title ?? "")];*/
            //print("loc \(self.location!.latitude),\(self.location!.longitude) - \(self.info.location!.latitude),\(self.info.location!.longitude)")
            url = url.appendingPathComponent("link")
                .appendingPathComponent("to")
                .appendingPathComponent("\(endName),\(end.latitude.description),\(end.longitude.description)");
            //url = urlComponents!.url!;
        }else{
            url = URL(string:"comgooglemaps://")!;
            //var urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: true);
            
            if !UIApplication.shared.canOpenURL(url){
                
                url = URL(string: "https://www.google.co.kr/maps/dir/\(self.latitude),\(self.longitude)/\(end.latitude),\(end.longitude)/@\(end.latitude),\(end.longitude),14z")!;
            }else{
                url = URL(string: "comgooglemap://?saddr=\(self.latitude),\(self.longitude)&daddr=\(end.latitude),\(end.longitude)")!;
            }
        }
        
        //print("http://map.daum.net/?sX=\(self.location!.latitude)&sY=\(self.location!.longitude)&sName=\("Current Location".localized())&eX=\(self.info.location!.latitude)&eY=\(self.info.location!.longitude)&eName=\(self.info.title)");
        print("open url \(url)");
        return url;
        //UIApplication.shared.open(url, options: [:], completionHandler: nil);
    }
}
