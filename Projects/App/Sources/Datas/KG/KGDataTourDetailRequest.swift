//
//  KGDataTourDetailRequest.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 4. 6..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreLocation

struct KGDataTourDetailRequest{
    var locale : Locale
    var id = 0;
    
    var needDefault = false;
    
    init(locale : Locale = Locale.current, id : Int) {
        self.locale = locale;
        self.id = id;
    }
    
    var urlRequest : URLRequest{
        get{
            let restUrl = KGDataAPI.RestURL.VisitKorea(locale).appendingPathComponent("detailCommon2");
            //let params : [String: AnyObject] = [:];
            var urlComponents = URLComponents(url: restUrl, resolvingAgainstBaseURL: true);
            var queries = urlComponents?.queryItems ?? [];
            
            queries.append(URLQueryItem(name: "_type", value: "json"));

            queries.append(URLQueryItem(name: "MobileOS", value: "IOS"));
            queries.append(URLQueryItem(name: "MobileApp", value: "wherewego"));
            queries.append(URLQueryItem(name: "contentId", value: "\(self.id)"));

            // KorService2 detailCommon2 already returns overview, address, images, and map fields
            // for a valid contentId. Legacy *YN flags now cause INVALID_REQUEST_PARAMETER_ERROR,
            // so keep the request to the required baseline parameters only.
            
            urlComponents?.queryItems = queries;
            
            var url = urlComponents?.url;
            
            //do not use queryitem for ServiceKey. / will be escaped not be encoded if it contains in
            url = URL(string: (url?.absoluteString ?? "") + "&ServiceKey=lWH3TH9hXhNio7cYKzu0MaGzl3lO3o8BP%2BbRpSOgubUXipVjY6Y1gmnIxIRKK3GJMJir1%2FdL72xt8WGc11mQ3Q%3D%3D");
            
            var req = URLRequest(url: url!);
            //        req.addValue("text/xml", forHTTPHeaderField: "Content-Type");
            req.httpMethod = "GET";
            
            return req;
        }
    }
}
