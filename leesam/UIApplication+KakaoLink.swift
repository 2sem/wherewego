//
//  UIApplication+KakaoLink.swift
//  democracyaction
//
//  Created by 영준 이 on 2017. 7. 7..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import KakaoLink
import KakaoMessageTemplate

extension UIApplication{
    func shareByKakao(){
        //let kakaoLink = KMTLinkObject();
        let kakaoContent = KMTContentObject.init { (builder) in
            builder.title = UIApplication.shared.displayName ?? "";
            builder.imageURL = URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Purple118/v4/49/34/ed/4934ed48-9f2d-d4ba-45d3-3c7722467720/mzl.jncdgkyy.png/150x150bb.jpg")!;
                //URL(string: "http://mud-kage.kakao.co.kr/14/dn/btqgX0q8UNy/IIuo0tK5W7TRUviC4VFBEK/o.jpg")!;
                //URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Purple118/v4/68/6a/19/686a194c-b5a8-ccd5-d63d-7fc0a3e25e6f/pr_source.png/150x150bb.jpg")!;
            builder.link = KMTLinkObject.init(builderBlock: { (linkBuilder) in
                var urlComponents = URLComponents(string: "http://search.daum.net/search");
                urlComponents?.queryItems = [URLQueryItem(name: "q", value: "공인중개사요약집")];
                linkBuilder.webURL = urlComponents!.url!;
            });
        }
        /*(title: "문자행동", imageURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Newsstand127/v4/d9/d4/9d/d9d49d1d-e062-4aa1-ca16-30c6a8023cf1/Icon-76@2x.png.png/0x0ss.png")!, link: kakaoLink);*/
        //kakaoContent.imageWidth = 120;
        //kakaoContent.imageHeight = 120; //160
        //kakaoContent.desc = "내 손안의 민주주의";
        
        let kakaoTemplate = KMTFeedTemplate.init(builderBlock: { (kakaoBuilder) in
            kakaoBuilder.content = kakaoContent;
            //kakaoBuilder.buttons?.add(kakaoWebButton);
            //link can't have more than two buttons
            // - content's url, button1 url, button2 url
            kakaoBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    linkBuilder.webURL = URL(string: "https://itunes.apple.com/us/app/id\(UIApplication.shared.appId)?mt=8");
                    linkBuilder.mobileWebURL = URL(string: "https://itunes.apple.com/us/app/id\(UIApplication.shared.appId)?mt=8");
                })
                buttonBuilder.title = "애플 앱스토어";
            }));
            
            kakaoBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    linkBuilder.webURL = URL(string: "https://play.google.com/store/apps/details?id=com.tarkarn.wherewego&hl=ko");
                    linkBuilder.mobileWebURL = URL(string: "https://play.google.com/store/apps/details?id=com.tarkarn.wherewego&hl=ko");
                    //linkBuilder.mobileWebURL = URL(string: "www.daum.net");
                })
                buttonBuilder.title = "구글플레이";
            }));
            /*kakaoBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    linkBuilder.webURL = URL(string: "https://youtu.be/0n0oQkLX_4s");
                    //linkBuilder.webURL = URL(string: "https://www.youtube.com/watch?v=0n0oQkLX_4s");

                    linkBuilder.mobileWebURL = linkBuilder.webURL;
                })
                buttonBuilder.title = "언론보도";
            }));
            
            kakaoBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    //linkBuilder.webURL = URL(string: "https://itunes.apple.com/us/app/id1243863489?mt=8");
                    //linkBuilder.mobileWebURL = URL(string: "https://itunes.apple.com/us/app/id1243863489?mt=8");
                })
                buttonBuilder.title = "다운로드";
            }));*/
            
            //https://youtu.be/0n0oQkLX_4s
        })
        
        KLKTalkLinkCenter.shared().sendDefault(with: kakaoTemplate, success: { (warn, args) in
            print("kakao warn[\(warn?.description ?? "")] args[\(args?.description ?? "")]")
        }, failure: { (error) in
            print("kakao error[\(error)]")
        })
    }
    
    func _shareByKakao(){
        let kakaoNews1 = KMTContentObject(title: "‘문자행동’ 어플 개발자 인터뷰···“민주주의 발전에 한손 보탤 수 있길”", imageURL: URL(string: "http://img.khan.co.kr/news/2017/06/23/l_2017062301003119000246131.jpg")!, link: KMTLinkObject(builderBlock: { (linkBuilder) in
            linkBuilder.webURL = URL(string: "http://news.khan.co.kr/kh_news/khan_art_view.html?artid=201706231651011&code=940100");
            //linkBuilder.webURL = URL(string: "http://www.daum.net");
            linkBuilder.mobileWebURL = linkBuilder.webURL;
        }));
        kakaoNews1.desc = "경향신문";
        let kakaoNews2 = KMTContentObject(title: "국회의원 연락처 한 곳에…‘문자행동’ 어플까지 나왔네", imageURL: URL(string: "http://img.hani.co.kr/imgdb/resize/2017/0623/00501745_20170623.JPG")!, link: KMTLinkObject(builderBlock: { (linkBuilder) in
            linkBuilder.webURL = URL(string: "http://www.hani.co.kr/arti/society/society_general/799996.html");
            linkBuilder.mobileWebURL = linkBuilder.webURL;
        }));
        kakaoNews2.desc = "한겨례";
        let kakaoNews3 = KMTContentObject(builderBlock: { (contentBuilder) in
            contentBuilder.title = "\"문자 폭탄\" VS \"문자 행동\" 논란 속에…'의견 앱' 등장";
            contentBuilder.desc = "SBS";
            contentBuilder.imageURL = URL(string: "https://www.youtube.com/watch?v=0n0oQkLX_4s")!;
            contentBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                linkBuilder.webURL = URL(string: "https://youtu.be/0n0oQkLX_4s");
                linkBuilder.mobileWebURL = linkBuilder.webURL;
            });
        })
        //kakaoNews3.desc = "SBS";
        
        let kakaoTemplate = KMTListTemplate(builderBlock: { (kakaoBuilder) in
            kakaoBuilder.headerTitle = "문자행동 - 내 손안의 민주주의";
            kakaoBuilder.headerLink = KMTLinkObject(builderBlock: { (linkBuilder) in
                var searchUrl = URLComponents(string: "http://search.daum.net/search");
                searchUrl?.queryItems = [URLQueryItem(name: "q", value: "문자행동")];
                linkBuilder.webURL = searchUrl?.url;
            });
            kakaoBuilder.contents = [kakaoNews1, kakaoNews2, kakaoNews3];
            //kakaoBuilder.buttons?.add(kakaoWebButton);
            //link can't have more than two buttons
            // - content's url, button1 url, button2 url
            kakaoBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    linkBuilder.webURL = URL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(UIApplication.shared.appId)&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8");
                    //linkBuilder.webURL = URL(string: "https://www.youtube.com/watch?v=0n0oQkLX_4s");
                    
                    linkBuilder.mobileWebURL = linkBuilder.webURL;
                })
                buttonBuilder.title = "응원하기";
            }));
            
            kakaoBuilder.addButton(KMTButtonObject(builderBlock: { (buttonBuilder) in
                buttonBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    //linkBuilder.webURL = URL(string: "https://itunes.apple.com/us/app/id1243863489?mt=8");
                    //linkBuilder.mobileWebURL = URL(string: "https://itunes.apple.com/us/app/id1243863489?mt=8");
                })
                buttonBuilder.title = "앱 다운로드";
            }));
            
            //https://youtu.be/0n0oQkLX_4s
        })
        
        KLKTalkLinkCenter.shared().sendDefault(with: kakaoTemplate, success: { (warn, args) in
            print("kakao warn[\(warn?.description ?? "")] args[\(args?.description ?? "")]")
        }, failure: { (error) in
            print("kakao error[\(error)]")
        })
    }
}
