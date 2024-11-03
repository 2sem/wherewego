//
//  KGDRangePickerViewController.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 5. 24..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps

protocol KGDRangePickerViewDelegate : NSObjectProtocol{
    func rangePickerView(picker: KGDRangePickerViewController, location: CLLocationCoordinate2D, radius: Int);
}

class KGDRangePickerViewController: UIViewController, GMSMapViewDelegate {

    var location : CLLocationCoordinate2D?;
    var hereMarker : GMSMarker!;
    var rangeCircle : GMSCircle!;
    
    private var _radius : Int = 1000 * 3;
    var radius : Int{
        get{
            return Int(self.rangeSlider.value * 1000);
        }
        set(value){
            self._radius = value;
            self.rangeSlider?.value = Float(self._radius / 1000);
        }
    }
    
    var delegate : KGDRangePickerViewDelegate?;
    
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var rangeSlider: UISlider!
    @IBOutlet weak var rangeLabel: UILabel!
//    @IBOutlet weak var mapViewContainer: UIView!
    @IBOutlet weak var mapView: GMSMapView!
    
    override func viewWillAppear(_ animated: Bool) {
        //self.reviewManager?.show();
        LSThemeManager.shared.apply(viewController: self);
        LSThemeManager.shared.apply(button: self.minusButton);
        LSThemeManager.shared.apply(button: self.plusButton);
        LSThemeManager.shared.apply(label: rangeLabel);
        LSThemeManager.shared.apply(slider: self.rangeSlider);
        //LSThemeManager.shared.apply(navigationController: self.navigationController);
        //LSThemeManager.shared.apply(barButton: self.rangeButton);
        //LSThemeManager.shared.apply(label: self.emptyView);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        if self.location == nil{
            self.location = CLLocationCoordinate2D.init(latitude: CLLocationDegrees(37.5866076), longitude: CLLocationDegrees(126.974811));
        }
        
//        self.mapView = self.generateMapView();
        
        //Shows button to show current location
        self.mapView.isMyLocationEnabled = true;
        self.mapView.settings.myLocationButton = true;
        
        //Sets default location?
        //self.mapView.delegate = self;

        
        //create maker
        self.hereMarker = GMSMarker(position: self.location!)
        self.hereMarker?.title = "Here";
        self.hereMarker?.map = self.mapView;
        self.hereMarker?.icon = GMSMarker.markerImage(with: UIColor.blue);
        self.hereMarker?.isDraggable = true;
        self.mapView?.delegate = self;
        
        self.radius = self._radius;

        //create circle to indicate search range
        self.rangeCircle = GMSCircle(position: self.hereMarker.position, radius: CLLocationDistance(self.radius));
        self.rangeCircle.map = self.mapView;
        self.rangeCircle.fillColor = UIColor.blue.withAlphaComponent(0.3);
        self.rangeCircle?.radius = CLLocationDistance(self.radius);
        
    
        self.onRangeChanged(self.rangeSlider);
        self.zoomToFit();
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func generateMapView() -> GMSMapView?{
        var mapView : GMSMapView!;
        
        guard let location = self.location else {
            return mapView;
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: 10);
//        mapView = GMSMapView.map(withFrame: self.mapViewContainer.frame, camera: camera)
//        self.mapViewContainer.addSubview(mapView);
        
        return mapView
    }
    
    @IBAction func onMinus(_ sender: UIButton) {
        self.rangeSlider.value -= 1.0;
        self.onRangeChanged(self.rangeSlider);
    }
    
    @IBAction func onPlus(_ sender: UIButton) {
        self.rangeSlider.value += 1.0;
        self.onRangeChanged(self.rangeSlider);
    }
    
    @IBAction func onRangeChanged(_ sender: UISlider) {
        self.rangeSlider.value = round(self.rangeSlider.value);
        self.minusButton.isEnabled = self.rangeSlider.value > self.rangeSlider.minimumValue;
        self.plusButton.isEnabled = self.rangeSlider.value < self.rangeSlider.maximumValue;
        self.rangeLabel.text = self.radius.stringForDistance();
        self.rangeCircle?.radius = CLLocationDistance(self.radius);
        //self.mapView.camera.zoom
        self.zoomToFit();
    }
    
    func zoomToFit(){
        print("zoom - \(10 + (self.rangeSlider.maximumValue - self.rangeSlider.value) * 0.1)");
        //self.mapView.animate(toZoom: 10 + (self.rangeSlider.maximumValue - self.rangeSlider.value) * 0.2);
        let mapBounds = self.rangeCircle.bounds;
        //GMSCoordinateBounds(coordinate: self.location!, coordinate: self.location!);
        let cameraUpdate = GMSCameraUpdate.fit(mapBounds, with: UIEdgeInsets.init(top: 44, left: 44, bottom: 44, right: 44));
        self.mapView.animate(with: cameraUpdate);
    }
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true);
        self.delegate?.rangePickerView(picker: self, location: self.hereMarker.position, radius: self.radius);
    }

    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        self.rangeCircle.position = marker.position;
    }
    
    /*func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        self.rangeCircle.position = mapView.camera.target;
        return false;
    }*/
    
    /*func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        guard !gesture else {
            return;
        }
        
        self.rangeCircle.position = mapView.camera.target;
    }*/
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
