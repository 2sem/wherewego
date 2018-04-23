//
//  ViewController.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 13..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMobileAds

class MainViewController: UIViewController, GADInterstialManagerDelegate, GADRewardManagerDelegate {

    class Constraints{
        static let BottomBanner_BOTTOM = "bottomBanner_BOTTOM";
    }
    
    var constraint_bottomBanner_Bottom : NSLayoutConstraint!;
    @IBOutlet weak var constraint_bottomBanner_Top: NSLayoutConstraint!
    //var constraint_bottomBanner_Top : NSLayoutConstraint!;
    
    @IBOutlet weak var bottomBannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if #available(iOS 11.0, *){
            self.constraint_bottomBanner_Bottom = self.bottomBannerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor);
        }else{
            self.constraint_bottomBanner_Bottom = self.bottomBannerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor);
        }
        self.constraint_bottomBanner_Bottom.isActive = false;
        
        self.bottomBannerView.loadUnitId(name: "BottomBanner");
        self.bottomBannerView.rootViewController = self;
        
        GADInterstialManager.shared?.delegate = self;
        GADRewardManager.shared?.delegate = self;
        
        //var req = GADRequest();
        //req.testDevices = ["5fb1f297b8eafe217348a756bdb2de56"];
        
        self.bottomBannerView.isAutoloadEnabled = true;
        /*guard (GADRewardManager.shared?.canShow ?? false) && (GADInterstialManager.shared?.canShow ?? false) else{
            return;
        }*/
        //self.bottomBannerView?.load(req);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func toggleContraint(value : Bool, constraintOn : NSLayoutConstraint, constarintOff : NSLayoutConstraint){
        if constraintOn.isActive{
            constraintOn.isActive = value;
            constarintOff.isActive = !value;
        }else{
            constarintOff.isActive = !value;
            constraintOn.isActive = value;
        }
    }
    
    private func showBanner(visible: Bool){
        guard self.constraint_bottomBanner_Bottom != nil
            && self.constraint_bottomBanner_Top != nil else{
                return;
        }
        
        self.toggleContraint(value: visible, constraintOn: constraint_bottomBanner_Bottom, constarintOff: constraint_bottomBanner_Top);
        
        if visible{
            print("show banner");
        }else{
            print("hide banner");
        }
        self.bottomBannerView.isHidden = !visible;
    }
    
    /// MARK: GADBannerViewDelegate
    @objc func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.showBanner(visible: true);
        print("gad banner loading has been completed");
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("failed to receive ad from google. error[\(error)] size[\(self.bottomBannerView.frame)] hidden[\(self.bottomBannerView.isHidden)]");
        self.showBanner(visible: false);
    }
    
    // MARK: GADInterstialManagerDelegate
    func GADInterstialGetLastShowTime() -> Date {
        return WWGDefaults.LastFullADShown;
        //Calendar.current.component(<#T##component: Calendar.Component##Calendar.Component#>, from: <#T##Date#>)
    }
    
    func GADInterstialUpdate(showTime: Date) {
        WWGDefaults.LastFullADShown = showTime;
        self.showBanner(visible: false);
    }
    
    // MARK: GADRewardManagerDelegate
    func GADRewardGetLastShowTime() -> Date {
        return WWGDefaults.LastRewardADShown;
    }
    
    func GADRewardUpdate(showTime: Date) {
        WWGDefaults.LastRewardADShown = showTime;
    }
    
    func GADRewardUserCompleted() {
        self.showBanner(visible: false);
    }
}

