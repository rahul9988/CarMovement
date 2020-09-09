//
//  LocationManager.swift
//  CarMovement
//
//  Created by Rahul Dhiman on Sep/9/20.
//  Copyright © 2020 Rahul Dhiman. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject,CLLocationManagerDelegate {
    private enum LocationUpdateMode{
        case justOnce
        case liveLocation
    }
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private var fetchMode: LocationUpdateMode?
    var location: CLLocation?
    typealias LocationManagerClosure = (_ location:CLLocation, _ city:String) -> Void
    private var closure: LocationManagerClosure?
    private var liveLocClosure: LocationManagerClosure?

    private override init() {
        super.init()
        self.setupLocationManager()
    }
    
    func setupLocationManager() {
        if location == nil {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 600 // meters
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func setupLocationManagerForLiveUpdates() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 20 // meters
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
        locationManager.requestAlwaysAuthorization()

    }
    
    func stopLiveUpdates() {
        if let mode = self.fetchMode {
            if mode == .liveLocation {
                self.liveLocClosure = nil
                self.locationManager.stopUpdatingLocation()
                self.locationManager.stopMonitoringSignificantLocationChanges()
            }
        }
    }
    
    func getUpdatedLocation( _ closure: @escaping LocationManagerClosure) {
        self.closure = closure
        self.fetchMode = .justOnce
        self.setupLocationManager()
        self.locationManager.startUpdatingLocation()
    }
    
    func getLiveLocationUpdates ( _ closure: @escaping LocationManagerClosure){
        self.liveLocClosure = closure
        self.fetchMode = .liveLocation
        self.setupLocationManagerForLiveUpdates()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingLocation()
    }
    
    func hasLocationAccess() -> Bool {
        var hasAccess = true
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                hasAccess = false
            case .authorizedAlways, .authorizedWhenInUse:
                hasAccess = true
            }
        } else {
            hasAccess = false
        }
        return hasAccess
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedWhenInUse ||
                status == .authorizedAlways
            {
                if let mode = self.fetchMode {
                    if mode == .justOnce
                    {
                        locationManager.startUpdatingLocation()
                    }
                    else if mode == .liveLocation
                    {
                        self.locationManager.startMonitoringSignificantLocationChanges()
                        self.locationManager.startUpdatingLocation()
                    }
                }
            }
    }
    // Show image and update self.location when locationManager updates location
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        self.location = locations.last
        location?.getLocationName { [weak self](name) in
            guard let `self` = self else {return}
            
            if let mode = self.fetchMode {
                if mode == .justOnce
                {
                    self.closure?(self.location!, name)
                    self.closure = nil
                    self.locationManager.stopUpdatingLocation()
                }
                    else if mode == .liveLocation
                {
                    self.liveLocClosure?(self.location!, name)
//                    self.liveLocClosure = nil // dont uncomment me ;)
                }
            }
           
        }
    }
}

extension LocationManager {
    
    private func log(msg:String, title:String? = nil) {
        print("Message is - \(msg)")
        print("Title is - \(title ?? "")")
    }
}

extension CLLocation : LocationNameGetter {
    var latitude: Double {
        get {
            let lat = self.coordinate.latitude
            return lat
        }
    }
    
    var longitude: Double {
        get {
            let long = self.coordinate.longitude
            return long
        }
    }
}

protocol LocationNameGetter {
    var latitude: Double { get }
    var longitude: Double { get }

    func getLocationName(_ completion:@escaping (String) -> ())
}

extension LocationNameGetter {
    func getLocationName(_ completion:@escaping (String) -> ())
    {
        let geoCoder = CLGeocoder()
        let location  = CLLocation(latitude: self.latitude, longitude: self.longitude)
        geoCoder.reverseGeocodeLocation(location) { (placeMarks, error) in
            guard let placeMark = placeMarks?.first else { return }
            var name = ""
            // Location name
            if let locationName = placeMark.name {
                print(locationName)
                name += locationName + ","
            }
            // Street address
            if let street = placeMark.thoroughfare {
                print(street)
                name += street + ","
            }
            // City
            if let city = placeMark.subAdministrativeArea {
                print(city)
                name += city + ","
                
            }
                // Zip code
            else if let zip = placeMark.isoCountryCode {
                print(zip)
                name = zip
            }
                // Country
            else if let country = placeMark.country {
                print(country)
                name = country
            }
            if name.last == "," {
                name = String(name.dropLast())
            }
            name = name.replacingOccurrences(of: ",", with: ", ")
            completion(name)
        }
    }
}
