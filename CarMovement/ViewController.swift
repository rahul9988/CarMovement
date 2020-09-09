//
//  ViewController.swift
//  CarMovement
//
//  Created by Rahul Dhiman on Sep/9/20.
//  Copyright © 2020 Rahul Dhiman. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {

    var mapView: GMSMapView! = GMSMapView.init()
    var car: GMSMarker!
    var oldCoordinate: CLLocationCoordinate2D! = CLLocationCoordinate2D(latitude: 19.126725, longitude: 73.0051247)
    var newCoordinate: CLLocationCoordinate2D!
    let carMovemnt = CarMovement()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        carMovemnt.delegate = self

        mapView.frame = self.view.bounds
        self.view.addSubview(mapView)
        mapView.isMyLocationEnabled = true
        
        moveCar()
        // Do any additional setup after loading the view.
    }
    
    func moveCar() {
        
        car = GMSMarker(position: oldCoordinate)
        car.icon = #imageLiteral(resourceName: "car")
        car.map = mapView
        let camUpdate = GMSCameraUpdate.setTarget(oldCoordinate, zoom: 15.0)
        mapView.animate(with: camUpdate)
        
        LocationManager.shared.getLiveLocationUpdates { [weak self] (loc, name) in
            guard let `self` = self else { return }
            self.newCoordinate = loc.coordinate
            
            self.carMovemnt.moveCar(marker: self.car,
                                          oldCoordinate: self.oldCoordinate,
                                          newCoordinate: self.newCoordinate,
                                          mapView: self.mapView,
                                          bearing: 0)
            self.oldCoordinate = self.newCoordinate
        }
        
    }
}

extension ViewController: CarMovementDelegate {
    func carDidMovedWith(_ marker: GMSMarker) {
        DispatchQueue.main.async {
            print("Marker Coordinates:: ",marker.position)
            let camUpdate = GMSCameraUpdate.setTarget(marker.position, zoom: 15.0)
            self.mapView.animate(with: camUpdate)
        }
    }
}
