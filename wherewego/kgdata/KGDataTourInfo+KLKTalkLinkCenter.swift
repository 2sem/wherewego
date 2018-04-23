//
//  KGDataTourInfo+KLKTalkLinkCenter.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 7. 10..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import KakaoLink
import KakaoMessageTemplate
import CoreLocation

extension KGDataTourInfo{
    func shareByKakao(_ location : CLLocationCoordinate2D){
        let kakaoLink = KMTLinkObject();
        //kakaoLink.webURL = URL(string: self.personHomepage?.url ?? "");
        kakaoLink.androidExecutionParams = "srcLatitude=\(location.latitude)"
            .appending("&srcLongitude=\(location.longitude)")
            .appending("&destLatitude=\(self.location!.latitude)")
            .appending("&destLongitude=\(self.location!.longitude)")
            .appending("&destTitle=\(self.title!)")
            .appending("&destAddress=\(self.primaryAddr ?? "") \(self.detailAddr ?? "")")
            .appending("&destPhoneNo=\(self.tel ?? " ")")
            .appending("&destDistance=\(self.distance ?? 0)")
            .appending("&destImageUrl=\(self.image?.absoluteString ?? " ")")
            .appending("&destContentId=\(self.id ?? 0)")
            .appending("&destContentTypeId=\(self.type.rawValue)")
            .appending("&destContentTypeText=\(self.type.stringValue)");
        
        kakaoLink.iosExecutionParams = "destContentId=\(self.id ?? 0)"
            .appending("&srcLatitude=\(location.latitude)")
            .appending("&srcLongitude=\(location.longitude)");
        
        //kakaoLink.iosExecutionParams = kakaoLink.iosExecutionParams!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed);*/
        var kakaoText : KMTTextTemplate!;
        var kakaoFeed : KMTFeedTemplate!;
        var kakaoContent : KMTContentObject!;
        if self.image != nil{
            kakaoContent = KMTContentObject(title: self.title ?? "", imageURL: self.image!, link: kakaoLink);
            kakaoContent.imageWidth = 120;
            kakaoContent.imageHeight = 1;
            kakaoContent.desc = "\(self.primaryAddr ?? "") \(self.detailAddr ?? "")\n"
            .appending("\(self.tel ?? "")\n\n");
            //.appending("\(self.overview ?? "")");
            
            kakaoFeed = KMTFeedTemplate.init(builderBlock: { (kakaoBuilder) in
                kakaoBuilder.content = kakaoContent;
                //kakaoBuilder.buttons?.add(kakaoWebButton);
                //link can't have more than two buttons
                // - content's url, button1 url, button2 url
                /*kakaoBuilder.addButton(KLKButtonObject(builderBlock: { (buttonBuilder) in
                 buttonBuilder.link = KLKLinkObject(builderBlock: { (linkBuilder) in
                 var searchUrl = URLComponents(string: "http://search.daum.net/search");
                 searchUrl?.queryItems = [URLQueryItem(name: "q", value: "\(self.title ?? "")")];
                 linkBuilder.webURL = searchUrl?.url;
                 //kakaoLink.webURL = URL(string:"http://www.assembly.go.kr/assm/memPop/memPopup.do?dept_cd=9770941")!;
                 linkBuilder.mobileWebURL = searchUrl?.url;
                 })
                 buttonBuilder.title = "검색";
                 }));*/
                
                /*kakaoBuilder.addButton(KLKButtonObject(builderBlock: { (buttonBuilder) in
                 buttonBuilder.link = KLKLinkObject(builderBlock: { (linkBuilder) in
                 if let webUrl = self.personHomepage?.url, !webUrl.isEmpty{
                 linkBuilder.webURL = URL(string: self.personHomepage?.url ?? "");
                 //kakaoLink.webURL = URL(string:"http://www.assembly.go.kr/assm/memPop/memPopup.do?dept_cd=9770941")!;
                 linkBuilder.mobileWebURL = URL(string: self.personHomepage?.url ?? "");
                 //kakaoLink.mobileWebURL = URL(string:"http://www.assembly.go.kr/assm/memPop/memPopup.do?dept_cd=9770941")!;
                 }
                 })
                 buttonBuilder.title = "홈페이지";
                 }));*/
                
                kakaoBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                    buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                        linkBuilder.webURL = kakaoLink.webURL;
                        linkBuilder.iosExecutionParams = kakaoLink.iosExecutionParams;
                        linkBuilder.androidExecutionParams = kakaoLink.androidExecutionParams;
                    })
                    buttonBuilder.title = "앱으로 열기";
                }));
            })
        }else{
            kakaoText = KMTTextTemplate.init(text: "\(self.title ?? "")\n\(self.primaryAddr ?? "") \(self.detailAddr ?? "")\n".appending("\(self.tel ?? "")\n\n"), link: kakaoLink);
            kakaoText.buttons = [KMTButtonObject(builderBlock: { (buttonBuilder) in
                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    linkBuilder.webURL = kakaoLink.webURL;
                    linkBuilder.iosExecutionParams = kakaoLink.iosExecutionParams;
                    linkBuilder.androidExecutionParams = kakaoLink.androidExecutionParams;
                })
                buttonBuilder.title = "앱으로 열기";
            })];
        }
        
        let kakaoTemplate : KMTTemplate! = self.image != nil ? kakaoFeed : kakaoText;
        DispatchQueue.main.syncInMain {
            KLKTalkLinkCenter.shared().sendDefault(with: kakaoTemplate, success: { (warn, args) in
                print("kakao share warn[\(warn?.description ?? "")] args[\(args?.description ?? "")]");
            }, failure: { (error) in
                print("kakao share error[\(error)] ios[\(kakaoLink.iosExecutionParams ?? "")]");
            })
        }
        
    }

}
