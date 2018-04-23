//
//  GMSCircle+.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 5. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleMaps

extension GMSCircle{
    var bounds : GMSCoordinateBounds{
        //let sign: Double = positive ? 1 : -1;
        let distance = self.radius / 6378000 * (180/Double.pi)
        let lefttop = CLLocationCoordinate2D(latitude: self.position.latitude - distance, longitude: self.position.longitude - distance);
        let rightbottom = CLLocationCoordinate2D(latitude: self.position.latitude + distance, longitude: self.position.longitude + distance);
        
        return GMSCoordinateBounds(coordinate: lefttop, coordinate: rightbottom);
    }
}
