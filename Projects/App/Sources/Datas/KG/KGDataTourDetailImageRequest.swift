//
//  KGDataTourDetailImageRequest.swift
//  wherewego
//

import Foundation

struct KGDataTourDetailImageRequest {
    var locale: Locale;
    var contentId: Int = 0;

    init(locale: Locale = Locale.current, contentId: Int) {
        self.locale = locale;
        self.contentId = contentId;
    }

    var urlRequest: URLRequest {
        get {
            let restUrl = KGDataAPI.RestURL.VisitKorea(locale).appendingPathComponent("detailImage2");
            var urlComponents = URLComponents(url: restUrl, resolvingAgainstBaseURL: true);
            var queries = urlComponents?.queryItems ?? [];
            queries.append(URLQueryItem(name: "_type", value: "json"));
            queries.append(URLQueryItem(name: "MobileOS", value: "IOS"));
            queries.append(URLQueryItem(name: "MobileApp", value: "wherewego"));
            queries.append(URLQueryItem(name: "contentId", value: "\(self.contentId)"));
            queries.append(URLQueryItem(name: "imageYN", value: "Y"));
            queries.append(URLQueryItem(name: "subImageYN", value: "Y"));
            urlComponents?.queryItems = queries;
            var url = urlComponents?.url;
            //do not use queryitem for ServiceKey. / will be escaped not be encoded if it contains in
            url = URL(string: (url?.absoluteString ?? "") + "&ServiceKey=lWH3TH9hXhNio7cYKzu0MaGzl3lO3o8BP%2BbRpSOgubUXipVjY6Y1gmnIxIRKK3GJMJir1%2FdL72xt8WGc11mQ3Q%3D%3D");
            var req = URLRequest(url: url!);
            req.httpMethod = "GET";
            return req;
        }
    }
}
