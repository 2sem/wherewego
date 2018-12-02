//
//  KGDTourInfoViewController.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 4. 4..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import SafariServices
import LSExtensions

class KGDTourInfoViewController: UITableViewController, GMSMapViewDelegate {

    var infoId : Int = 0;
    var info : KGDataTourInfo!;
    var currentLocation : CLLocationCoordinate2D?;
    
    //@IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageButton: UIButton!
    
    @IBOutlet weak var telButton: UIButton!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    
    @IBOutlet weak var addrIconImageView: UIImageView!
    @IBOutlet weak var addrTitleLabel: UILabel!
    @IBOutlet weak var addrLabel: UILabel!
    @IBOutlet weak var detailAddrLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var overviewIconImageView: UIImageView!
    @IBOutlet weak var overviewTitleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    
    fileprivate var hereMarker : GMSMarker!;
    fileprivate var targetMarker : GMSMarker!;
    //var reviewManager : ReviewManager?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        LSThemeManager.shared.apply(viewController: self);
        LSThemeManager.shared.apply(roundButton: self.telButton);
        LSThemeManager.shared.apply(roundButton: self.routeButton);
        LSThemeManager.shared.apply(roundButton: self.searchButton);
        LSThemeManager.shared.apply(label: self.addrTitleLabel);
        LSThemeManager.shared.apply(label: self.addrLabel);
        LSThemeManager.shared.apply(label: self.overviewTitleLabel);
        LSThemeManager.shared.apply(label: self.overviewLabel);
        self.addrIconImageView.tintColor = UIColor.white;
        self.overviewIconImageView.tintColor = UIColor.white;
        
        if self.info != nil{
            self.infoId = self.info.id ?? 0;
        }
        
        let handle = {[unowned self] in
            // MARK: Shows property of this tour informations
            //loads image of this tour infomation
            self.imageButton.imageView?.contentMode = .scaleAspectFill;
            self.loadImage();
            self.navigationItem.title = self.info?.title;
            self.addrLabel.text = (self.info.primaryAddr ?? "") + " " +  (self.info.detailAddr ?? "");
            
            //Shows current location and this destination's location on Google Map
            self.mapView.camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.latitude, longitude: self.currentLocation!.longitude, zoom: 10);
            
            let mapBounds = GMSCoordinateBounds(coordinate: self.currentLocation!, coordinate: self.info.location!);
            let cameraUpdate = GMSCameraUpdate.fit(mapBounds, with: UIEdgeInsets.init(top: 44, left: 44, bottom: 10, right: 44));
            self.mapView.animate(with: cameraUpdate);
            
            //Sets marker for current location
            if self.currentLocation != nil{
                self.hereMarker = GMSMarker(position: self.currentLocation!)
                self.hereMarker.title = "Here";
                self.hereMarker.map = self.mapView;
                self.hereMarker.icon = GMSMarker.markerImage(with: UIColor.blue);
            }
            
            //Sets marker for this tour location
            self.targetMarker = GMSMarker(position: self.info.location!)
            self.targetMarker.title = self.info.title;
            self.targetMarker.map = self.mapView;
        };
        
        if self.info != nil {
            handle();
        }
        
        KGDataTourManager.shared.requestDetail(contentId: self.infoId, needDefault: self.info == nil) { [unowned self](detailInfo, error) in
            DispatchQueue.main.async {
                if self.info == nil{
                    self.info = detailInfo;
                }
                self.info.overview = detailInfo?.overview;
                handle();
                self.tableView.reloadData();
                
                let mapBounds = GMSCoordinateBounds(coordinate: self.currentLocation!, coordinate: self.info.location!);
                let cameraUpdate = GMSCameraUpdate.fit(mapBounds, with: UIEdgeInsets.init(top: 44, left: 44, bottom: 10, right: 44));
                self.mapView.animate(with: cameraUpdate);
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        ReviewManager.shared?.show();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onShare(_ button: UIBarButtonItem) {
        if Locale.current.isKorean {
            self.info.shareByKakao(self.currentLocation ?? self.info.location!);
        }else{
            //Share google map site if user isn't korean
            self.share([self.imageButton.image(for: .normal) ?? UIImage(),
                        "[\(self.info.title ?? "")] \(self.info.tel ?? "")",
                self.currentLocation?.urlForGoogleRoute(startName: "Current Location".localized(), end: self.info.location!, endName: self.info.title ?? "Destination".localized()) ?? ""]);
        }
    }
    
    @IBAction func onPhoneCall(_ button: UIButton) {
        guard self.info.tel != nil else{
            return;
        }
        
        UIApplication.shared.openTel(self.info.tel ?? "");
    }
    
    @IBAction func onRoute(_ sender: UIButton) {
        /*guard UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!) else{
            return;
        }*/
        
        var url = URL(string:"http://map.daum.net")!;
        //var urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: true);
        
        //var url = URL(string: "http://map.daum.net/?sX=\(self.location!.latitude)&sY=\(self.location!.longitude)&sName=\("Current Location".localized())&eX=\(self.info.location!.latitude)&eY=\(self.info.location!.longitude)&eName=\(self.info.title)");
        //open url http://map.daum.net?sX=37.5199176930241
        //                            &sY=126.88215125364
        //                            &sName=Current%20Location
        //                            &eX=37.5162467956543
        //                            &eY=126.889793395996
        //                            &eName=%EC%98%81%EC%9D%BC%EB%B6%84%EC%8B%9D
//12632.09061058575
//8801.892062560384
        
        //if user is korean?
        print("locale \(Locale.current.identifier)")
        if Locale.current.isKorean {
            //Opens daum map
            //korea?
            /*urlComponents?.queryItems = [URLQueryItem(name: "sX", value: "\(self.location!.latitude * 12632.09061058575)"),
                URLQueryItem(name: "sY", value: "\(self.location!.longitude * 8801.892062560384)"),
                URLQueryItem(name: "sName", value: "Current Location"),
                URLQueryItem(name: "eX", value: "\(self.info.location!.latitude * 12632.09061058575)"),
                URLQueryItem(name: "eY", value: "\(self.info.location!.longitude * 8801.892062560384)"),
                URLQueryItem(name: "eName", value: self.info.title ?? "")];*/
            print("loc \(self.currentLocation!.latitude),\(self.currentLocation!.longitude) - \(self.info.location!.latitude),\(self.info.location!.longitude)")
            url = url.appendingPathComponent("link")
                .appendingPathComponent("to")
                .appendingPathComponent("\(self.info.title ?? ""),\(self.info.location!.latitude),\(self.info.location!.longitude)");
            //url = urlComponents!.url!;
        }else{
            //Opens google map if user is foreigner
            url = URL(string:"comgooglemaps://")!;
            //var urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: true);
            
            //if google map is not installed on this device
            if !UIApplication.shared.canOpenURL(url){
                //Opens google map site
                url = URL(string: "https://www.google.co.kr/maps/dir/\(self.currentLocation!.latitude),\(self.currentLocation!.longitude)/\(self.info.location!.latitude),\(self.info.location!.longitude)/@\(self.mapView.camera.target.latitude),\(self.mapView.camera.target.longitude),14z")!;
            }else{
                url = URL(string: "comgooglemap://?saddr=\(self.currentLocation!.latitude),\(self.currentLocation!.longitude)&daddr=\(self.info.location!.latitude),\(self.info.location!.longitude)")!;
            }
        }
        
        //print("http://map.daum.net/?sX=\(self.location!.latitude)&sY=\(self.location!.longitude)&sName=\("Current Location".localized())&eX=\(self.info.location!.latitude)&eY=\(self.info.location!.longitude)&eName=\(self.info.title)");
        print("open url \(url)");
        //UIApplication.shared.open(url, options: [:], completionHandler: nil);
        let webView = SFSafariViewController.init(url: url);
        self.present(webView, animated: true, completion: nil);
    }
    
    @IBAction func onSearch(_ button: UIButton) {
        if Locale.current.isKorean{
            UIApplication.shared.searchByDaum(self.info.title ?? "");
        }else{
            UIApplication.shared.searchByGoogle(self.info.title ?? "");
        }
    }

    func loadImage(){
        guard !self.isMovingFromParentViewController else{
            return;
        }
        
        self.imageButton.sd_setImage(with: self.info?.image, for: .normal, placeholderImage: WWGImages.noImage);
    }
    
    // MARK: - Table view data source

    /*override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }*/

    /*override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }*/
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var value = super.tableView(tableView, heightForRowAt: indexPath);
        //return value;
        
        switch indexPath.row{
            case 1:
                value = self.addrLabel.frame.height + self.addrLabel.frame.origin.y + 5;
                break;
            case 2:
                value = self.view.frame.height / 3;
                break;
            case 3:
                guard let info = self.info else{
                    return value;
                }
                
                if self.overviewLabel.text != info.overview{
                    self.overviewLabel.text = info.overview;
                    self.overviewLabel.sizeToFit();
                }
                //value = 100;
                value = self.overviewLabel.frame.height + self.overviewLabel.frame.origin.y;
                break;
            default:
                break;
        }
        
        return value;
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    // MARK: GMSMapViewDelegate

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let imageView = segue.destination as? KGDImageViewController{
            imageView.imageUrl = self.info?.image;
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
