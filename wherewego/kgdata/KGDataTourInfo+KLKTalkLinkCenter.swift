//
//  KGDataTourInfo+KLKTalkLinkCenter.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 7. 10..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import KakaoSDKShare
import KakaoSDKTemplate
import CoreLocation

extension KGDataTourInfo{
    func shareByKakao(_ location : CLLocationCoordinate2D){
        let kakaoLink = Link.init(androidExecutionParams: ["srcLatitude":location.latitude.description,
                                                           "srcLongitude":location.longitude.description,
                                                           "destLatitude":self.location!.latitude.description,
                                                           "destLongitude":self.location!.longitude.description,
                                                           "destTitle":self.title!,
                                                           "destAddress":"\(self.primaryAddr ?? "") \(self.detailAddr ?? "")",
                                                           "destPhoneNo":self.tel ?? " ",
                                                           "destDistance":(self.distance ?? 0).description,
                                                           "destImageUrl":self.image?.absoluteString ?? " ",
                                                           "destContentId":(self.id ?? 0).description,
                                                           "destContentTypeId":self.type.rawValue.description,
                                                           "destContentTypeText":self.type.stringValue],
                                  iosExecutionParams: ["destContentId":(self.id ?? 0).description,
                                                       "srcLatitude": location.latitude.description,
                                                       "srcLongitude": location.longitude.description]);
        
        var kakaoText : TextTemplate!;
        var kakaoFeed : FeedTemplate!;
        var kakaoContent : Content!;
        if let image = self.image{
            kakaoContent = Content.init(title: self.title ?? "",
                                        imageUrl: image,
                                        imageWidth: 120,
                                        imageHeight: 1,
                                        description: "\(self.primaryAddr ?? "") \(self.detailAddr ?? "")\n".appending("\(self.tel ?? "")\n\n"),
                                        link: kakaoLink)
            kakaoFeed = FeedTemplate.init(content: kakaoContent, buttons: [Button.init(title: "앱으로 열기", link: kakaoLink)])
        }else{
            kakaoText = TextTemplate.init(text: "\(self.title ?? "")\n\(self.primaryAddr ?? "") \(self.detailAddr ?? "")\n".appending("\(self.tel ?? "")\n\n"),
                                          link: kakaoLink, buttonTitle: "앱으로 열기",
                                          buttons: [Button.init(title: "앱으로 열기", link: kakaoLink)])
        }
        
        let kakaoTemplate : Templatable! = self.image != nil ? kakaoFeed : kakaoText;
//        DispatchQueue.main.syncInMain {
            guard ShareApi.isKakaoTalkSharingAvailable() else {
                guard let kakaoWebUrl = ShareApi.shared.makeDefaultUrl(templatable: kakaoTemplate) else { return }
                UIApplication.shared.open(kakaoWebUrl)
                return
            }
            
            ShareApi.shared.shareDefault(templatable: kakaoTemplate) { result, error in
                guard let result = result else {
                    debugPrint("kakao share error[\(error)] ios[\(kakaoLink.iosExecutionParams ?? "")]");
                    return
                }
                
                debugPrint("kakao share warn[\(result.warningMsg?.description ?? "")] args[\(result.argumentMsg?.description ?? "")]");
                UIApplication.shared.open(result.url)
            }
        
//            KLKTalkLinkCenter.shared().sendDefault(with: kakaoTemplate, success: { (warn, args) in
//                print("kakao share warn[\(warn?.description ?? "")] args[\(args?.description ?? "")]");
//            }, failure: { (error) in
//                print("kakao share error[\(error)] ios[\(kakaoLink.iosExecutionParams ?? "")]");
//            })
//        }
        
    }

}
