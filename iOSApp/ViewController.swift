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
    var gpsList:[String] = []
    
    @IBOutlet var latlonLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var gpsPointNumLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    let cellIdentifier = "cell"
    var items = ["empty"]

    required init(coder aDecoder: NSCoder) {
        self.lm = CLLocationManager()
        self.longitude = CLLocationDegrees()
        self.latitude = CLLocationDegrees()
        super.init(coder: aDecoder)
    }
    
    @IBAction func btnGetLocation(sender: AnyObject) {
        // get lat and long
        self.lm.startUpdatingLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        
        // 現在地の取得
        self.lm = CLLocationManager()
        self.lm.delegate = self
        // 取得精度の設定
        self.lm.desiredAccuracy = kCLLocationAccuracyBest
        // 取得頻度の設定
        self.lm.distanceFilter = 100
        
        if lm.respondsToSelector("requestWhenInUseAuthorization") {
            // iOS8
            // セキュリティ認証のステータスを取得
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .NotDetermined:
                println("not determined")
                // まだ認証が得られていない場合は、認証ダイアログを表示
                self.lm.requestAlwaysAuthorization()
            case .Authorized:
                println("authorized")
                self.lm.startUpdatingLocation()
            case .AuthorizedWhenInUse:
                println("authorized when in use")
                self.lm.startUpdatingLocation()
            case .Denied:
                println("denied");
            case .Restricted:
                println("restricted");
            }
        }
        else {
            // iOS7未満
            self.lm.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .Authorized:
            println("authorized")
            self.lm.startUpdatingLocation()
        case .AuthorizedWhenInUse:
            println("authorized when in use")
            self.lm.startUpdatingLocation()
        case .Denied:
            println("denied")
        case .NotDetermined:
            println("not determined")
        case .Restricted:
            println("restricted")
        }
    }
    
    // 位置情報取得成功時
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!){
        
        latitude = newLocation.coordinate.latitude
        longitude = newLocation.coordinate.longitude
        let latlon = "\(latitude),\(longitude)"
        self.latlonLabel.text = latlon
        
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
        
        addGps(latlon)
        gpsPointNumLabel.text = String(self.gpsList.count)
        self.updateShopTable()
    }
    
    // 未登録の値のみ追加
    func addGps(elem :String) {
        for latlon in self.gpsList {
            if equalLatlon(latlon, elem2: elem) {
                return
            }
        }
        self.gpsList.append(elem)
    }
    
    // lat,lonの先頭7文字かが一致したら、同一緯度経度と判定
    // TODO Geohashでぶつからなかったら登録するにした方がいいかも
    func equalLatlon(elem1 :String, elem2 :String) -> Bool {
        let comp1 = elem1.substringToIndex(advance(elem1.startIndex, 6))
        let comp2 = elem2.substringToIndex(advance(elem2.startIndex, 6))
        return comp1 == comp2
    }
    
    // 位置情報表示
    func displayLocationInfo(placemark: CLPlacemark) {
        var address: String = ""
        address = placemark.postalCode != nil ? placemark.postalCode : ""
        address += ","
        address += placemark.country != nil ? placemark.country : ""
        address += ","
        address += placemark.administrativeArea != nil ? placemark.administrativeArea : ""
        address += ","
        address += placemark.locality != nil ? placemark.locality : ""
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
    func updateShopTable() {
        // init items of TableView
        self.items = []
        
        // get shops and update TableView
        for gps in self.gpsList {
            getShops(gps)
            // strXMLData が非同期に平行アクセスされて、おかしくなる可能性が考えられるため、スリープを入れている
            sleep(1)
        }
    }
    
    // 非同期アクセスでお店リストを取得し、取得できたら、現状のテーブルと結合して再表示
    func getShops(gps: String) {
        var gpsArr = gps.componentsSeparatedByString(",")
        
        // 周辺1kmのお店取得
        var urlStr = "http://search.olp.yahooapis.jp/OpenLocalPlatform/V1/localSearch?"
        urlStr += "appid=" + yahooAppId
        urlStr += "&lat=" + gpsArr[0]
        urlStr += "&lon=" + gpsArr[1]
        urlStr += "&dist=1"
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
        addItems(cells)
        self.tableView.reloadData()
    }
    
    // お店の追加。ただし、同じ店名があったら追加しない
    func addItems(cells :[String]) {
        for cell in cells {
            var flag = true
            for item in self.items {
                if cell == item {
                    flag = false
                    break
                }
            }
            if flag {
                self.items.append(cell)
            }
        }
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
        cell.textLabel?.text = self.items[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("You selected cell #\(indexPath.row)!")
    }
}
