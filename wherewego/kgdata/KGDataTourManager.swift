//
//  KGDataTourManager.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 22..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import LSExtensions

class KGDataTourManager: NSObject {    
    static private(set) var shared = KGDataTourManager();
    private(set) var currentPage = 0;
    typealias TourListCompletionHandler = (_ page: Int, _ items: [KGDataTourInfo], _ total: Int, _ error: NSError?) -> Void
    typealias TourDetailCompletionHandler = (_ info: KGDataTourInfo?, _ error: NSError?) -> Void
    
    var queueGroup  : DispatchGroup = DispatchGroup();
    private var lastListRequest : KGDataTourListRequest?;
    
    func requestList(request req: KGDataTourListRequest, completion:  @escaping TourListCompletionHandler){
        print("request \(req.urlRequest)");
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        URLSession.shared.dataTask(with: req.urlRequest) { (resData, res, error) in
            UIApplication.offNetworking();

            let resultString = String(data: resData ?? Data(), encoding: .utf8);
            guard error == nil else{
                print("fail response \(error.debugDescription) - \(resultString ?? "") - \(res?.description ?? "")");
                return;
            }
            
            print("succ response \(error.debugDescription) - \(resultString ?? "") - \(res?.description ?? "")");
            
            do{
                /*
                 "response":{"header":{"resultCode":"0000",\"resultMsg":"OK"},"body":{"items":{"item":[{...}, {...}, {...}]
                 */
                print("start parsing json");
                var json = try JSONSerialization.jsonObject(with: resData ?? Data(), options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject] ?? [:];
                var response = json["response"] as? [String : AnyObject] ?? [:];
                let header = KGDataTourResponseHeader(response["header"] as? [String : AnyObject] ?? [:]);
                
                var body = response["body"] as? [String : AnyObject] ?? [:];
                var container = body["items"] as? [String : AnyObject] ?? [:];
                let items = container["item"] as? [[String : AnyObject]] ?? [];
                var tourInfos : [KGDataTourInfo] = [];
                for item in items{
                    tourInfos.append(KGDataTourInfo(item));
                }
                
                print("tour infos - \(tourInfos.count) - response[\(response)] body[\(body)] container[\(container)] items[\(items)]");
                
                //pageNo : received page number
                //totalCount : total record count
                
                completion(Int(header.page), tourInfos, Int(header.total), nil);
            }catch let error{
                print("json error - \(error)");
                completion(0, [], 5, error as NSError);
            }
        }.resume();
    }
    
    func requestList(locale : Locale = Locale.current, type : KGDataTourInfo.ContentType? = nil, location : CLLocationCoordinate2D, radius : UInt, completion:  @escaping TourListCompletionHandler) -> KGDataTourListRequest?{
        //request
        //numOfRows : max result for a row
        //pageNo : page number to get
        //arrange : sort kind
        // - A : default, sort by title
        // - B : sort by view count
        // - C : sort by last modified
        // - D : sort by date
        // - E : sort by distance **
        //* MobileOS : os for device
        // - IOS : iPhone
        // - AND : Android
        // - WIN : Windows Phone
        // - ETC : etc
        //* MobileApp : Service Name or App Name
        //* mapX : X Coordinate
        //* mapY : Y Coordinate
        //* radius : search distance (max : 20000m = 20km)
        
        //response - header
        //resultCode : result code
        //resultMsg : msg for result code
        //numOfRows : max result for a row
        //pageNo : received page number
        //totalCount : total record count
        //resposse - item
        //addr1 : simple address
        //addr2 : additional address
        //areacode : location id
        //booktour : this item in the school book?(1: true, 0: false)
        //cat1 : first category
        //cat2 : second category
        //cat3 : third category
        //contentid : Contend Id(item id?)
        //contenttypeid : content kind id
        //createdtime : registered time
        //dist : distance to this item from (mapX, mapY)
        //firstimage : original
        //firstimage2 : thumbnail
        //mapx : item coordinate x
        //mapy : item coordinate y
        //mlevel : map level
        //modifiedtime : last modified time
        //readcount : count this item is read
        //sigunucode : code for city, town
        //tel : item's phone number
        //title : item's name
        
        /*
         {\"items\":{\"item\":[{\"addr1\":\"경상북도 경주시 불국신택지1길 31\",\"addr2\":\"(진현동)\",\"areacode\":35,\"cat1\":\"A03\",\"cat2\":\"A0302\",\"cat3\":\"A03020200\",\"contentid\":131706,\"contenttypeid\":28,\"createdtime\":20040225000000,\"dist\":33,\"firstimage\":\"http:\\/\\/tong.visitkorea.or.kr\\/cms\\/resource\\/96\\/1891396_image2_1.jpg\",\"firstimage2\":\"http:\\/\\/tong.visitkorea.or.kr\\/cms\\/resource\\/96\\/1891396_image3_1.jpg\",\"mapx\":129.3236455903,\"mapy\":35.7845210292,\"mlevel\":6,\"modifiedtime\":20170207112238,\"readcount\":24485,\"sigungucode\":2,\"title\":\"계림유스호스텔\"}
         */
        
        let req = KGDataTourListRequest(locale: locale, type: type, location : location, radius : radius);
        
        self.requestList(request: req, completion: completion);
        
        return req;
    }
    
    func requestDetail(request req: KGDataTourDetailRequest, completion:  @escaping TourDetailCompletionHandler){
        print("request \(req.urlRequest)");
        
        UIApplication.onNetworking();
        URLSession.shared.dataTask(with: req.urlRequest) { (resData, res, error) in
            UIApplication.offNetworking();

            let resultString = String(data: resData ?? Data(), encoding: .utf8);
            guard error == nil else{
                print("fail response \(error.debugDescription) - \(resultString ?? "") - \(res?.description ?? "")");
                return;
            }
            
            print("succ response \(error.debugDescription) - \(resultString ?? "") - \(res?.description ?? "")");
            
            do{
                /*
                 "response":{"header":{"resultCode":"0000",\"resultMsg":"OK"},"body":{"items":{"item":[{...}, {...}, {...}]
                 */
                print("start parsing json");
                var json = try JSONSerialization.jsonObject(with: resData ?? Data(), options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject] ?? [:];
                var response = json["response"] as? [String : AnyObject] ?? [:];
                //let header = KGDataTourResponseHeader(response["header"] as? [String : AnyObject] ?? [:]);
                
                var body = response["body"] as? [String : AnyObject] ?? [:];
                let items = body["items"] as? [String : AnyObject] ?? [:];
                let item = items["item"] as? [String : AnyObject] ?? [:];

                let tourInfo : KGDataTourInfo? = KGDataTourInfo(item);
                print("tour detail info - \(tourInfo?.description ?? "") - response[\(response)] body[\(body)]");
                
                //pageNo : received page number
                //totalCount : total record count
                
                completion(tourInfo, nil);
            }catch let error{
                print("json error - \(error)");
                completion(nil, error as NSError);
            }
            }.resume();
    }
    
    @discardableResult
    func requestDetail(locale : Locale = Locale.current, contentId: Int, needDefault: Bool = false, completion:  @escaping TourDetailCompletionHandler) -> KGDataTourDetailRequest?{
        var req = KGDataTourDetailRequest(locale: locale, id : contentId);
        req.needDefault = needDefault;
        
        self.requestDetail(request: req, completion: completion);
        
        return req;
    }
}
