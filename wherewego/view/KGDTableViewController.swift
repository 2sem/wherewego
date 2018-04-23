//
//  KGDTableViewController.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 29..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import CoreLocation
import DownPicker
import MBProgressHUD
import LSExtensions

class KGDTableViewController: UITableViewController, CLLocationManagerDelegate, KGDRangePickerViewDelegate {
    static let cell_id = "KGDTableViewCell";
    
    var location : CLLocationCoordinate2D?;
    var locManager : CLLocationManager = CLLocationManager();
    var reviewManager : ReviewManager?;
    
    fileprivate static var _shared : KGDTableViewController?;
    static var shared : KGDTableViewController?{
        get{
            return _shared;
        }
    }
    
    var infos : [KGDataTourInfo] = [];
    var radius : Int = 3000{
        didSet{
            self.rangeButton.setTitle(self.radius.stringForDistance(), for: .normal);
            WWGDefaults.Range = self.radius;
        }
    }
    
    var imageLoadingQueue = OperationQueue()

    var lastKGDRequest : KGDataTourListRequest?;
    var typePicker : UIDownPicker!;
    //var typePickerView : UIPickerView!;
    var currentType : KGDataTourInfo.ContentType?{
        get{
            let typeIndex = self.typePicker.downPicker.selectedIndex;
            guard typeIndex > 0 else{
                return nil;
            }
            
            var value = KGDataTourInfo.ContentType.values[typeIndex - 1];
            if !Locale.current.isKorean{
                value = KGDataTourInfo.ContentType.values_foreign[typeIndex - 1];
            }
            
            return value;
        }
    }
    
    static var startingQuery : URL?{
        didSet{
            /*var nav = UIApplication.shared.keyWindow?.rootViewController as? MainViewController;
            guard nav != nil else{
                return;
            }*/
            
            guard startingQuery != nil else{
                return;
            }
            
            print("set startingQuery - \(startingQuery?.debugDescription ?? "")");
            var urlComponent = URLComponents(url: KGDTableViewController.startingQuery!, resolvingAgainstBaseURL: true);
            guard urlComponent?.queryItems != nil else{
                return;
            }
            
            //if nav?.topViewController is KGDTableViewController{
            if KGDTableViewController.shared?.shouldPerformSegue(withIdentifier: "tourInfo", sender: KGDTableViewController.shared) ?? false{
                KGDTableViewController.shared?.performSegue(withIdentifier: "tourInfo", sender: KGDTableViewController.shared);
            }
            //}else{
                /*nav?.popViewController(animated: false);
                KGDTableViewController.shared?.performSegue(withIdentifier: "tourInfo", sender: KGDTableViewController.shared);
            }*/
        }
    }
    
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var centerButton: UIBarButtonItem!
    @IBOutlet weak var rangeButton: UIButton!
    var emptyView : UILabel?;
    
    override func viewWillAppear(_ animated: Bool) {
        //self.reviewManager?.show();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        if KGDTableViewController._shared == nil{
            KGDTableViewController._shared = self;
        }
        
        /*
         case Tour = 12
         case Culture = 14
         case Event = 15
         case Course = 25
         case Reports = 28
         case Hotel = 32
         case Shopping = 38
         case Food = 39
         case Travel = 40
         */
        var types = ["All Tour Informations".localized()];
        
        if Locale.current.identifier.hasPrefix("ko"){
            for type in KGDataTourInfo.ContentType.values{
                types.append(type.stringValue.localized());
            }
        }else{
            for type in KGDataTourInfo.ContentType.values_foreign{
                types.append(type.stringValue.localized());
            }
        }
        
        self.typePicker = UIDownPicker(data: types);
        self.typePicker.downPicker.selectedIndex = 0;
        self.typeButton.setTitle("\(self.typePicker.text?.localized() ?? "") ▼", for: .normal);
        self.typeButton.sizeToFit();
        self.typePicker.downPicker.addTarget(self, action: #selector(onTypeSelected(_:)), for: .valueChanged);
        self.view.addSubview(self.typePicker);
        
        self.radius = WWGDefaults.Range;
        self.rangeButton.setTitle(self.radius.stringForDistance(), for: .normal);
        print("range button - \(self.rangeButton.title)");
        //self.typePicker.setData(["a", "b", "c", "d", "e", "f"]);
        //self.typePicker.show(self.typePicker);
        //self.typeButton.inputView = self.typePickerView;
        
        self.locManager.delegate = self;
        self.locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        //kCLLocationAccuracyHundredMeters;
        //kCLLocationAccuracyNearestTenMeters
        //kCLLocationAccuracyBestForNavigation
        
        self.locManager.distanceFilter = 500;
        self.locManager.requestWhenInUseAuthorization();
        //        self.locManager.startUpdatingLocation();
        //self.requestLocation();
        self.refreshControl?.addTarget(self, action: #selector(refresh(control:)), for: .valueChanged);
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.emptyView = UILabel();
        self.emptyView?.text = "No data available in a current range.\nIncrease range or move the marker to another place.\nCheck if the marker or you are in Korea.".localized();
        self.tableView.backgroundView = self.emptyView;
        self.emptyView?.numberOfLines = 0;
        self.emptyView?.sizeToFit();
        self.emptyView?.topAnchor.constraint(equalTo: self.view.topAnchor);
        self.emptyView?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor);
        self.emptyView?.leftAnchor.constraint(equalTo: self.view.leftAnchor);
        self.emptyView?.rightAnchor.constraint(equalTo: self.view.rightAnchor);
        self.emptyView?.textAlignment = .center;
        
        if KGDTableViewController.startingQuery != nil{
            KGDTableViewController.shared?.performSegue(withIdentifier: "tourInfo", sender: KGDTableViewController.shared);
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //self.reviewManager?.show();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func refresh(control : UIRefreshControl){
        self.refreshInfos();
    }
    
    func requestLocation(){
        print("request current location");
        let hub = MBProgressHUD.showAdded(to: self.view, animated: true);
        hub.mode = .indeterminate;
        hub.label.text = "Tracking Location".localized();
        //        hub.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1);
        hub.contentColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1);

        self.centerButton.isEnabled = false;
        self.locManager.requestLocation();
    }
    
    func refreshInfos(){
        //        self.location = CLLocationCoordinate2D(latitude: CLLocationDegrees(35.7845967), longitude: CLLocationDegrees(129.3240082));
        guard self.location != nil else{
            self.requestLocation();
            return;
        }
        
        self.infos.removeAll();
        self.imageLoadingQueue.cancelAllOperations();
        //page: Int, count: Int, total: Int
        self.lastKGDRequest = KGDataTourManager.shared.requestList(type: currentType, location: self.location!, radius: UInt(self.radius)) { (page, infos, total, error) in
            
            for (i, info) in infos.enumerated(){
                print("#info(\(i))# \(info)");
            }
            
            self.infos.append(contentsOf: infos);
            DispatchQueue.main.async {
                self.tableView.reloadData();
                self.refreshControl?.endRefreshing();
            }
        }
    }
    
    @objc func onTypeSelected(_ picker: DownPicker){
        guard self.currentType != nil else{
            self.typeButton.setTitle("\(picker.text.localized()) ▼", for: .normal);
            self.typeButton.setImage(nil, for: .normal);
            self.typeButton.sizeToFit();
            self.refreshInfos();
            return;
        }
        
        print("selected \(picker)");
        self.typeButton.setImage(self.currentType?.image, for: .normal);
        self.typeButton.setTitle("\(self.currentType!.stringValue.localized()) ▼", for: .normal);
        self.typeButton.sizeToFit();
        self.refreshInfos();
    }
    
    @IBAction func onSelectType(_ sender: UIButton) {
        //self.typePicker.show(self.typePicker);
        self.typePicker.becomeFirstResponder();
    }
    
    @IBAction func onSelectCenter(_ sender: UIBarButtonItem) {
        self.requestLocation();
    }
    
    @IBAction func onSelectRange(_ sender: UIButton) {
        
    }
    
    @IBAction func onReview(_ sender: UIBarButtonItem) {
        ReviewManager.shared?.show(true);
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.infos.count;
    }

    //var imageQueue = DispatchQueue(label: "tour info image loading");
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: KGDTableViewController.cell_id, for: indexPath) as? KGDTableViewCell;
        
        guard self.infos.count > indexPath.row else{
            return cell!;
        }
        
        let info = self.infos[indexPath.row];
        // Configure the cell...
        cell?.backgroundImageView.image = nil;
        
        
        self.imageLoadingQueue.addOperation {
        //imageQueue.async {
            var image : UIImage? = UIImage();
            do{
                if info.thumbnail != nil{
                    image = try UIImage(data: Data(contentsOf: info.thumbnail!));
                }
            }catch{
                
            }
            
            DispatchQueue.main.async {
                guard tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false else{
                    return;
                }
                
                cell?.backgroundImageView.image = image;
                if image?.size.height == 0 || image?.size.width == 0{
                    cell?.backgroundImageView.image = WWGImages.noImage;
                }
            }
        }
        
        cell?.titleLabel.text = info.title;
        cell?.distanceLabel.text = info.distance?.stringForDistance();

        //check reach 2 rows before end
        if indexPath.row == self.infos.count - 2{
            self.lastKGDRequest = self.lastKGDRequest?.next;
            KGDataTourManager.shared.requestList(request: self.lastKGDRequest!) { (page, infos, total, error) in
                guard error == nil else{
                    print("request more error - \(error.debugDescription)");
                    return;
                }
                
                self.infos.append(contentsOf: infos);
                var newIndexes : [IndexPath] = [];
                for (i, _) in infos.enumerated(){
                    let newIndex = IndexPath(row: indexPath.row + i + 1,
                                              section: indexPath.section);
                    newIndexes.append(newIndex);
                    
                }
                
                print("request more page[\(page)] total[\(total)]");

                DispatchQueue.main.async {
                    tableView.insertRows(at: newIndexes, with: .automatic);
                }
            }
        }
        
        return cell!;
    }
    
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

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.refreshControl?.endRefreshing();
        MBProgressHUD.hide(for: self.view, animated: true);
        print("location error \(error)");
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location updated \(locations)");
        MBProgressHUD.hide(for: self.view, animated: true);
        self.centerButton.isEnabled = true;

        guard !(self.location?.isEqual(locations.first?.coordinate) ?? false) else{
            manager.stopUpdatingLocation();
            return;
        }
        
        self.location = locations.first?.coordinate;
        
        self.refreshInfos();
        manager.stopUpdatingLocation();
        
        guard locations.first != nil else{
            return;
        }
        let geoCoder = CLGeocoder();
        geoCoder.reverseGeocodeLocation(locations.first!) { (marks, error) in
            print("here is \(marks?.first?.isoCountryCode.debugDescription ?? "")");
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("location permission \(status.rawValue)");

        switch status{
            case .authorizedAlways, .authorizedWhenInUse, .notDetermined, .restricted:
                MBProgressHUD.hide(for: self.view, animated: true);
                self.requestLocation();
                break;
            case .denied:
                self.openSettingsOrCancel(title: "\"WhereWeGo\" needs to use your location", msg: "This app will not work without the location permission.", style: .alert, titleForOK: "Ok", titleForSettings: "Settings");
                break;
        }
    }
    
    // MARK: KGDRangePickerViewDelegate
    func rangePickerView(picker: KGDRangePickerViewController, location: CLLocationCoordinate2D, radius: Int) {
        guard self.location?.latitude != location.latitude || self.location?.longitude != location.longitude || self.radius != radius else{
            return;
        }
        
        self.location = location;
        self.radius = radius;
        self.refreshInfos();
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let view = segue.destination as? KGDTourInfoViewController{
            if KGDTableViewController.startingQuery != nil{
                var urlComponent = URLComponents(url: KGDTableViewController.startingQuery!, resolvingAgainstBaseURL: true);
                let srcLat = urlComponent?.queryItems?.first(where: { (query) -> Bool in
                    return query.name == "srcLatitude";
                })?.value ?? "";
                let srcLong = urlComponent?.queryItems?.first(where: { (query) -> Bool in
                    return query.name == "srcLongitude";
                })?.value ?? "";
                let contentId = urlComponent?.queryItems?.first(where: { (query) -> Bool in
                    return query.name == "destContentId";
                })?.value ?? "";
                
                if !srcLat.isEmpty && !srcLong.isEmpty{
                    view.location = CLLocationCoordinate2D(latitude: CLLocationDegrees(srcLat)!, longitude: CLLocationDegrees(srcLong)!);
                }
                view.infoId = Int(contentId)!;
                KGDTableViewController.startingQuery = nil;
            }else if let cell = sender as? KGDTableViewCell{
                 if cell.backgroundImageView.image != nil{
                    //view.imageButton?.setImage(cell.backgroundImageView?.image, for: .normal);
                    var indexPath = self.tableView.indexPath(for: cell);
                    guard indexPath != nil  else {
                        return;
                    }
                    let info = self.infos[indexPath!.row];
                    view.info = info;
                    view.location = self.location;
                    //self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: false);
                }
            }
        }else if let view = segue.destination as? KGDRangePickerViewController{
            view.location = self.location;
            view.delegate = self;
            view.radius = self.radius;
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var value = true;
        
        if let cell = sender as? KGDTableViewCell{
            value = cell.backgroundImageView.image != nil;
        }else if let view = self.navigationController?.topViewController as? KGDTourInfoViewController{
            if KGDTableViewController.startingQuery != nil{
                var urlComponent = URLComponents(url: KGDTableViewController.startingQuery!, resolvingAgainstBaseURL: true);
                
                let contentId = urlComponent?.queryItems?.first(where: { (query) -> Bool in
                    return query.name == "destContentId";
                })?.value ?? "";
                
                value = view.info.id != Int(contentId);
            }
        }
        
        return value;
    }
}
