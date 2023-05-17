//
//  UIApplication+KakaoLink.swift
//  democracyaction
//
//  Created by 영준 이 on 2017. 7. 7..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import KakaoSDKShare
import KakaoSDKTemplate

extension UIApplication{
    func shareByKakao(){
        //let kakaoLink = KMTLinkObject();
        let appStoreUrl = URL.init(string: "https://itunes.apple.com/us/app/id\(UIApplication.shared.appId)?mt=8")
        
        let kakaoContent = Content.init(title: UIApplication.shared.displayName ?? "",
                                        imageUrl: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Purple118/v4/49/34/ed/4934ed48-9f2d-d4ba-45d3-3c7722467720/mzl.jncdgkyy.png/150x150bb.jpg")!,
                                        link: Link.init(mobileWebUrl: appStoreUrl,
                                                        androidExecutionParams: ["q": "공인중개사요약집"],
                                                        iosExecutionParams: ["q": "공인중개사요약집"]))
        /*(title: "문자행동", imageURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Newsstand127/v4/d9/d4/9d/d9d49d1d-e062-4aa1-ca16-30c6a8023cf1/Icon-76@2x.png.png/0x0ss.png")!, link: kakaoLink);*/
        //kakaoContent.imageWidth = 120;
        //kakaoContent.imageHeight = 120; //160
        //kakaoContent.desc = "내 손안의 민주주의";
        let googlePlayUrl = URL.init(string: "https://play.google.com/store/apps/details?id=com.tarkarn.wherewego&hl=ko&gl=US&pli=1")
        let kakaoLink = Link.init(webUrl: appStoreUrl,  mobileWebUrl: appStoreUrl)
//        let kakaoTemplate = TextTemplate.init(text: "내 손안의 민주주의", link: kakaoLink,
        let kakaoTemplate = FeedTemplate.init(content: kakaoContent,
                                              buttons: [.init(title: "애플 앱스토어", link: .init(webUrl: appStoreUrl,  mobileWebUrl: appStoreUrl)),
                                                        .init(title: "구글플레이", link: .init(webUrl: googlePlayUrl,  mobileWebUrl: googlePlayUrl))])
        
        guard ShareApi.isKakaoTalkSharingAvailable() else {
            guard let kakaoWebUrl = ShareApi.shared.makeDefaultUrl(templatable: kakaoTemplate) else { return }
            UIApplication.shared.open(kakaoWebUrl)
            return
        }
        
        ShareApi.shared.shareDefault(templatable: kakaoTemplate) { result, error in
            guard let result = result else {
                print("kakao share error[\(error)] ios[\(kakaoLink.iosExecutionParams ?? "")]");
                return
            }
            
            debugPrint("kakao share warn[\(result.warningMsg?.description ?? "")] args[\(result.argumentMsg?.description ?? "")]");
            UIApplication.shared.open(result.url)
        }
        
//        ShareApi.shared().sendDefault(with: kakaoTemplate, success: { (warn, args) in
//            print("kakao warn[\(warn?.description ?? "")] args[\(args?.description ?? "")]")
//        }, failure: { (error) in
//            print("kakao error[\(error)]")
//        })
    }
}
