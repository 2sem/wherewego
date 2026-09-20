//
//  KGDataTourInfo.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 16..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class KGDataTourInfo : KGDataTourObject {
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
    
    class fieldNames{
        static let id = "contentid";
        static let type = "contenttypeid";
        
        static let title = "title";
        static let tel = "tel";
        static let primaryAddr = "addr1";
        static let detailAddr = "addr2";
        static let image = "firstimage";
        static let thumbnail = "firstimage2";
        
        static let longitude = "mapx";
        static let latitude = "mapy";
        static let distance = "dist";
        static let hitCount = "readcount";
        
        static let createdTime = "createdtime";
        static let lastModified = "modifiedtime";
        
        static let overview = "overview";
    }
    
//    static let fieldNames = ["contentId":"contentid"];
//    static let fieldNames = ["contentid":"id", "contenttypeid":"type", "title":"title", "addr1":"primaryAddr", "addr2":"detailAddr", "firstimage":"image", "firstimage2":"thumbnail", "mapx":"longitude", "mapy":"latitude", "distance":"distance", "readcount":"hitCount", "createdTime":"createdTime", "modifiedtime":"lastModified"];

//    static let fieldNames = ["id":"contentid", "contenttypeid":"type", "title":"title", "addr1":"primaryAddr", "addr2":"detailAddr", "firstimage":"image", "firstimage2":"thumbnail", "mapx":"longitude", "mapy":"latitude", "distance":"distance", "readcount":"hitCount", "createdTime":"createdTime", "modifiedtime":"lastModified"];
    
    enum ContentType : Int{
        case Tour = 12
        case Culture = 14
        case Event = 15
        case Course = 25
        case Leports = 28
        case Hotel = 32 //bed
        case Shopping = 38
        case Food = 39 //restaurant
        case Travel = 40
        
        case Tour_Foreign = 76
        case Culture_Foreign = 78
        case Event_Foreign = 85
        case Leports_Foreign = 75
        case Hotel_Foreign = 80 //bed
        case Shopping_Foreign = 79
        case Food_Foreign = 82 //restaurant
        case Travel_Foreign = 77
        
        var stringValue : String{
            get{
                var value = self;
                
                switch value{
                    case .Tour_Foreign: value = .Tour;
                        break;
                    case .Culture_Foreign: value = .Culture;
                        break;
                    case .Event_Foreign: value = .Event;
                        break;
                    //case .Course_Foreign:
                        //break;
                    case .Leports_Foreign: value = .Leports;
                        break;
                    case .Hotel_Foreign: value = .Hotel;
                        break;
                    case .Shopping_Foreign: value = .Shopping;
                        break;
                    case .Food_Foreign: value = .Food;
                        break;
                    case .Travel_Foreign: value = .Travel;
                        break;
                    default:
                        break;
                }
                
                return "\(value)";
                //return Mirror(reflecting: value).children.first?.label ?? "";
            }
        }
        
        static let values : [ContentType] = [.Tour, .Culture, .Event, .Course, .Leports, .Hotel, .Shopping, .Food, .Travel];
        static let values_foreign : [ContentType] = [.Tour_Foreign, .Culture_Foreign, .Event_Foreign, .Leports_Foreign, .Hotel_Foreign, .Shopping_Foreign, .Food_Foreign, .Travel_Foreign];
        
        static let images : [UIImage] = [UIImage(named: "icon_tour.png")!, UIImage(named: "icon_culture.png")!,
                                         UIImage(named: "icon_event.png")!, UIImage(named: "icon_course.png")!,
                                         UIImage(named: "icon_leports.png")!, UIImage(named: "icon_bed.png")!,
                                         UIImage(named: "icon_shopping.png")!, UIImage(named: "icon_food.png")!,
                                         UIImage(named: "icon_travel.png")!];
        
        static let images_foreign : [UIImage] = [UIImage(named: "icon_tour.png")!, UIImage(named: "icon_culture.png")!,
                                         UIImage(named: "icon_event.png")!,
                                         UIImage(named: "icon_leports.png")!, UIImage(named: "icon_bed.png")!,
                                         UIImage(named: "icon_shopping.png")!, UIImage(named: "icon_food.png")!,
                                         UIImage(named: "icon_travel.png")!];
        
        var image : UIImage{
            get{
                let index = Locale.current.identifier.hasPrefix("ko") ? ContentType.values.index(of: self) : ContentType.values_foreign.index(of: self);
                
                return Locale.current.identifier.hasPrefix("ko") ? ContentType.images[index!] : ContentType.images_foreign[index!];
            }
        }
    }

    func parseToContentType(_ obj : AnyObject?) -> ContentType{
        var value : ContentType = .Tour;
        
        if let num = obj as? NSNumber{
            value = ContentType(rawValue: Int(truncating: num)) ?? .Tour;
        }else if let str = obj as? String{
            let num = Int(str);
            value = ContentType(rawValue: num!) ?? .Tour;
        }else if let type = obj as? ContentType{
            value = type;
        }
        
        return value;
    }
    
    var id : Int?{
        get{
            return self.parseToInt(self.fields[fieldNames.id]);
        }
        
        set(value){
            self.fields[fieldNames.id] = value as AnyObject?;
        }
    }
    var title : String?{
        get{
            return self.parseToString(self.fields[fieldNames.title]);
        }
        
        set(value){
            self.fields[fieldNames.title] = value as AnyObject?;
        }
    }
    var overview : String?{
        get{
            return self.parseToString(self.fields[fieldNames.overview])?
                .replacingOccurrences(of: "<br />", with: "\n")
                .replacingOccurrences(of: "<br>", with: "\n");
        }
        
        set(value){
            self.fields[fieldNames.overview] = value as AnyObject?;
        }
    }
    var tel : String?{
        get{
            return self.parseToString(self.fields[fieldNames.tel]);
        }
        
        set(value){
            self.fields[fieldNames.tel] = value as AnyObject?;
        }
    }
    
    var primaryAddr : String?{
        get{
            return self.parseToString(self.fields[fieldNames.primaryAddr]);
        }
        
        set(value){
            self.fields[fieldNames.primaryAddr] = value as AnyObject?;
        }
    }

    var detailAddr : String?{
        get{
            return self.parseToString(self.fields[fieldNames.detailAddr]);
        }
        
        set(value){
            self.fields[fieldNames.detailAddr] = value as AnyObject?;
        }
    }

    var type : ContentType{
        get{
            return self.parseToContentType(self.fields[fieldNames.type]);
        }
        
        set(value){
            self.fields[fieldNames.type] = value as AnyObject?;
        }
    }

    var createdTime : Date?{
        get{
            return self.parseToDate(self.fields[fieldNames.createdTime]);
        }
        
        set(value){
            self.fields[fieldNames.createdTime] = value as AnyObject?;
        }
    }

    var distance : Int?{
        get{
            return self.parseToInt(self.fields[fieldNames.distance]);
        }
        
        set(value){
            self.fields[fieldNames.distance] = value as AnyObject?;
        }
    }

    var image : URL?{
        get{
            return self.parseToUrl(self.fields[fieldNames.image]);
        }
        
        set(value){
            self.fields[fieldNames.image] = value as AnyObject?;
        }
    }

    var thumbnail : URL?{
        get{
            return self.parseToUrl(self.fields[fieldNames.thumbnail]);
        }
        
        set(value){
            self.fields[fieldNames.thumbnail] = value as AnyObject?;
        }
    }

    var longitude : Float?{
        get{
            return self.parseToFloat(self.fields[fieldNames.longitude]);
        }
        
        set(value){
            self.fields[fieldNames.longitude] = value as AnyObject?;
        }
    }

    var latitude : Float?{
        get{
            return self.parseToFloat(self.fields[fieldNames.latitude]);
        }
        
        set(value){
            self.fields[fieldNames.latitude] = value as AnyObject?;
        }
    }
    
    var location: CLLocationCoordinate2D?{
        get{
            var value : CLLocationCoordinate2D?;
            
            guard self.latitude != nil else{
                return value;
            }
            
            guard self.longitude != nil else{
                return value;
            }
            
            value = CLLocationCoordinate2D(latitude: CLLocationDegrees(self.latitude!), longitude: CLLocationDegrees(self.longitude!));
            
            return value;
        }
    }

    var lastMofidied : Date?{
        get{
            return self.parseToDate(self.fields[fieldNames.lastModified]);
        }
        
        set(value){
            self.fields[fieldNames.lastModified] = value as AnyObject?;
        }
    }

    var hitCount : Int?{
        get{
            return self.parseToInt(self.fields[fieldNames.hitCount]);
        }
        
        set(value){
            self.fields[fieldNames.hitCount] = value as AnyObject?;
        }
    }
    
    override init(){
        
    }
    
    init(_ json : [String : AnyObject]){
        super.init();
        self.fromJson(json);
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        let info : KGDataTourInfo? = object as? KGDataTourInfo;
        return self.id == info?.id;
    }
    
    override var description: String{
        return "id[\(self.id?.description ?? "")] title[\(self.title ?? "")] addr[\(self.primaryAddr ?? "")] detailAddr[\(self.detailAddr ?? "")] type[\(self.type)] created[\(self.createdTime?.description ?? "")] distance[\(self.distance?.description ?? "")] image[\(self.image?.description ?? "")] thumbnail[\(self.thumbnail?.description ?? "")] long[\(self.longitude?.description ?? "")] lat[\(self.latitude?.description ?? "")] lastModified[\(self.lastMofidied?.description ?? "")] hitCount[\(self.hitCount?.description ?? "")]";
    }
}
