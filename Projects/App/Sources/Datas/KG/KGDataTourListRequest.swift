//
//  KGDataTourRequest.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 26..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreLocation

class KGDataTourListRequest : KGDataTourRequest{
    var locale : Locale = Locale.current;
    var type : KGDataTourInfo.ContentType? = .Tour;
    var location : CLLocationCoordinate2D;
    var radius : UInt = 3000;
    var page = 1;
    
    init(locale : Locale = Locale.current, type : KGDataTourInfo.ContentType? = nil, location : CLLocationCoordinate2D, radius : UInt) {
        self.locale = locale;
        self.type = type;
        self.location = location;
        self.radius = radius;
    }
    
    var urlRequest : URLRequest{
        get{
            let restUrl = KGDataAPI.RestURL.VisitKorea(locale).appendingPathComponent("locationBasedList2");
            //let params : [String: AnyObject] = [:];
            var urlComponents = URLComponents(url: restUrl, resolvingAgainstBaseURL: true);
            var queries = urlComponents?.queryItems ?? [];
            
            //        queries.append(URLQueryItem(name: "ServiceKey", value: "lWH3TH9hXhNio7cYKzu0MaGzl3lO3o8BP%2BbRpSOgubUXipVjY6Y1gmnIxIRKK3GJMJir1%2FdL72xt8WGc11mQ3Q%3D%3D".removingPercentEncoding));
            
            //.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            //"lWH3TH9hXhNio7cYKzu0MaGzl3lO3o8BP%2BbRpSOgubUXipVjY6Y1gmnIxIRKK3GJMJir1%2FdL72xt8WGc11mQ3Q%3D%3D"
            //"lWH3TH9hXhNio7cYKzu0MaGzl3lO3o8BP+bRpSOgubUXipVjY6Y1gmnIxIRKK3GJMJir1/dL72xt8WGc11mQ3Q%3D%3D"
            //.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            queries.append(URLQueryItem(name: "pageNo", value: "\(self.page)"));
            queries.append(URLQueryItem(name: "_type", value: "json"));
            //
            queries.append(URLQueryItem(name: "arrange", value: "E"));
            
            
            if type != nil{
                queries.append(URLQueryItem(name: "contentTypeId", value: "\(type?.rawValue ?? KGDataTourInfo.ContentType.Tour.rawValue)"));
            }
            
            queries.append(URLQueryItem(name: "MobileOS", value: "IOS"));
            queries.append(URLQueryItem(name: "MobileApp", value: "wherewego"));
            //129.3240082, 35.7845967
            queries.append(URLQueryItem(name: "mapX", value: location.longitude.description));
            queries.append(URLQueryItem(name: "mapY", value: location.latitude.description));
            queries.append(URLQueryItem(name: "radius", value: radius.description));
            
            urlComponents?.queryItems = queries;
            
            var url = urlComponents?.url;
            
            //do not use queryitem for ServiceKey. / will be escaped not be encoded if it contains in
            url = URL(string: (url?.absoluteString ?? "") + "&ServiceKey=\(self.serviceKey)");
            
            var req = URLRequest(url: url!);
            //        req.addValue("text/xml", forHTTPHeaderField: "Content-Type");
            req.httpMethod = "GET";
            
            return req;
        }
    }
    
    var next : KGDataTourListRequest{
        get{
            let req = KGDataTourListRequest.init(locale: self.locale, type: self.type, location: self.location, radius: self.radius);
            
            req.page = page + 1;
            
            return req;
        }
    }
}
