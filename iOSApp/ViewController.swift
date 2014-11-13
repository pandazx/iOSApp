//
//  ViewController.swift
//  iOSApp
//
//  Created by kenji on 2014/11/03.
//  Copyright (c) 2014年 kenji. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, NSXMLParserDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let yahooAppId = "dj0zaiZpPVQzb20wbm9PUHkyayZzPWNvbnN1bWVyc2VjcmV0Jng9YWU-"

    var lm:CLLocationManager
    var longitude: CLLocationDegrees
    var latitude: CLLocationDegrees
    
    @IBOutlet var latlonLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    let cellIdentifier = "cell"
    var items = ["empty"]

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
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        
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
        
        self.updateShopTable(latitude, longitude: longitude)
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

    var strXMLData:String = ""
    var currentElement:String = ""
    var passHit:Bool = false
    var passData:Bool = false
    var passName:Bool = false
    var firstName:Bool = true
    
    // lat=35.665662327484, lon=139.73091159273
    
    // get shop list by YLOP and update TableView
    func updateShopTable(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // 周辺3kmのお店取得
        var urlStr = "http://search.olp.yahooapis.jp/OpenLocalPlatform/V1/localSearch?"
        urlStr += "appid=" + yahooAppId
        urlStr += "&lat=" + latitude.description
        urlStr += "&lon=" + longitude.description
        urlStr += "&dist=3"
        let url = NSURL(string: urlStr)
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            //println(NSString(data: data, encoding: NSUTF8StringEncoding))
            if self.parseXML(data) {
                self.updateTableData(self.strXMLData)
            }
        }
        task.resume()
    }
    
    func parseXML(data: NSData) -> Bool {
        var parser = NSXMLParser(data: data)
        parser.delegate = self
        var success:Bool = parser.parse()
        
        if success {
            println(self.strXMLData)
            return true
        } else {
            println("parse failure!")
            return false
        }
    }
    
    func updateTableData(strXMLData: String) {
        var cells = strXMLData.componentsSeparatedByString(",")
        // 先頭の不要なカンマで作成された要素を削除
        cells.removeAtIndex(0)
        self.items = cells
        self.tableView.reloadData()
    }
    
    func parser(parser: NSXMLParser!,didStartElement elementName: String!, namespaceURI: String!, qualifiedName : String!, attributes attributeDict: NSDictionary!) {
        currentElement = elementName
        if elementName == "Feature" {
            passHit = true
        }
        if firstName && elementName == "Name" {
            passName = true
            passData = true
            firstName = false
        }
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        currentElement = ""
        if elementName == "Feature" {
            passHit = false
            firstName = true
        }
        if elementName == "Name" {
            passName=false
            passData=false
        }
    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if passData {
            //strXMLData += "\n" + string
            strXMLData += "," + string
        }
    }
    
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!) {
        NSLog("failure error: %@", parseError)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier) as UITableViewCell
        cell.textLabel.text = self.items[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("You selected cell #\(indexPath.row)!")
    }
}
