//
//  ViewController.swift
//  iOSApp
//
//  Created by kenji on 2014/11/03.
//  Copyright (c) 2014年 kenji. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var lm:CLLocationManager
    var longitude: CLLocationDegrees
    var latitude: CLLocationDegrees
    
    @IBOutlet var latlonLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!

    required init(coder aDecoder: NSCoder) {
        lm = CLLocationManager()
        longitude = CLLocationDegrees()
        latitude = CLLocationDegrees()
        super.init(coder: aDecoder)
    }
    
    @IBAction func btnGetLocation(sender: AnyObject) {
        // get lat and long
        lm.startUpdatingLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 現在地の取得
        lm = CLLocationManager()
        lm.delegate = self
        
        // セキュリティ認証のステータスを取得
        let status = CLLocationManager.authorizationStatus()
        
        // まだ認証が得られていない場合は、認証ダイアログを表示
        if status == CLAuthorizationStatus.NotDetermined {
            println("didChangeAuthorizationStatus:\(status)");
            // まだ承認が得られていない場合は、認証ダイアログを表示
            self.lm.requestAlwaysAuthorization()
        }
        
        // 取得精度の設定
        lm.desiredAccuracy = kCLLocationAccuracyBest
        // 取得頻度の設定
        lm.distanceFilter = 100
    }

    // 位置情報取得成功時
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!){
        
        longitude = newLocation.coordinate.longitude
        latitude = newLocation.coordinate.latitude
        self.latlonLabel.text = "\(longitude), \(latitude)"
        
        // get address info
        CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: {(placemarks, error)->Void in
            if error != nil {
                println("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            if placemarks.count > 0 {
                let pm = placemarks[0] as CLPlacemark
                self.displayLocationInfo(pm)
                //stop updating location to save battery life
                self.lm.stopUpdatingLocation()
            } else {
                println("Problem with the data received from geocoder")
            }
        })
    }
    
    // 位置情報表示
    func displayLocationInfo(placemark: CLPlacemark) {
        var address: String = ""
        address = placemark.locality != nil ? placemark.locality : ""
        address += ","
        address += placemark.postalCode != nil ? placemark.postalCode : ""
        address += ","
        address += placemark.administrativeArea != nil ? placemark.administrativeArea : ""
        address += ","
        address += placemark.country != nil ? placemark.country : ""
        self.addressLabel.text = address
    }
    
    // 位置情報取得失敗時
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        NSLog("Error while updating location. " + error.localizedDescription)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
