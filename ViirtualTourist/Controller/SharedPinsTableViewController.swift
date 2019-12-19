//
//  SharedPinsTableViewController.swift
//  ViirtualTourist
//
//  Created by Mohammed Khakidaljahdali on 19/12/2019.
//  Copyright © 2019 Mohammed. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class SharedPinsTableViewController: UITableViewController {
    
    var db: Firestore!
    var pins: [SharedPin] = []
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("did appear")
        getSharedPins()
        tableView.reloadData()
    }
    
    func getSharedPins() {
        print("hey")
        db.collection("sharedPins").addSnapshotListener { (documents, error) in
            guard let documents = documents else {return}
            self.pins.removeAll()
            for document in documents.documents {
                let longitude = document.data()["longitude"] as! Double
                let latitude = document.data()["latitude"] as! Double
                let pageNumber = document.data()["pageNumber"] as! Int
                let owner = document.data()["owner"] as! String
                var city: String = ""
                let location = CLLocation(latitude: latitude, longitude: longitude)
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                    guard let placemark = placemarks?.first else {
                        let errorString = error?.localizedDescription ?? "Unexpected Error"
                        print("Unable to reverse geocode the given location. Error: \(errorString)")
                        return
                    }
                    DispatchQueue.main.async {
                        city = placemark.locality!
                        let sharedPin = SharedPin(latitude: latitude, longitude: longitude, pageNumber: pageNumber, owner: owner, city: city)
                        self.pins.append(sharedPin)
                        self.tableView.reloadData()
                        print(sharedPin)
                    }
                }
            }
            self.tableView.reloadData()
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return pins.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = pins[indexPath.row].owner
        cell.detailTextLabel?.text = "\(pins[indexPath.row].city)"
        return cell
    }
    
    func showCollection(sharedPin: SharedPin) {
        let vc = storyboard?.instantiateViewController(identifier: "imageCollectionView") as! ImageCollectionViewController
        vc.pin2 = Pin2(latitude: sharedPin.latitude, longitude: sharedPin.longitude)
        vc.pinID = "\(sharedPin.longitude)&\(sharedPin.latitude)"
//        vc.authUI = authUI
        vc.db = db
        vc.user = user
        present(vc, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sharedPin = pins[indexPath.row]
        showCollection(sharedPin: sharedPin)
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension SharedPinsTableViewController {
    
    func getLocation(location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in

            guard let placemark = placemarks?.first else {
                let errorString = error?.localizedDescription ?? "Unexpected Error"
                print("Unable to reverse geocode the given location. Error: \(errorString)")
                return
            }
            
            placemark.locality
            
            // Apple Inc.,
            // 1 Infinite Loop,
            // Cupertino, CA 95014
            // United States
        }
    }
//    func getAddressForLatLng(latitude: String, longitude: String)  { // Call this function
//
//         let url = NSURL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)")//Here pass your latitude, longitude
//         print(url!)
//         let data = NSData(contentsOf: url! as URL)
//
//         if data != nil {
//            let json = try! JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
//            print(json)
//
//            let status = json["status"] as! String
//            if status == "OK" {
//
//                if let result = json["results"] as? NSArray   {
//
//                    if result.count > 0 {
//                        if let addresss:NSDictionary = result[0] as? NSDictionary {
//                            if let address = addresss["address_components"] as? NSArray {
//                                var newaddress = ""
//                                var number = ""
//                                var street = ""
//                                var city = ""
//                                var state = ""
//                                var zip = ""
//                                var country = ""
//                                var district = ""
//
//                                if(address.count > 1) {
//                                    number =  (address.object(at: 0) as! NSDictionary)["short_name"] as! String
//                                }
//                                if(address.count > 2) {
//                                    street = (address.object(at: 1) as! NSDictionary)["short_name"] as! String
//                                }
//                                if(address.count > 3) {
//                                    city = (address.object(at: 2) as! NSDictionary)["short_name"] as! String
//                                }
//                                if(address.count > 4) {
//                                    state = (address.object(at: 4) as! NSDictionary)["short_name"] as! String
//                                }
//                                if(address.count > 6) {
//                                    zip =  (address.object(at: 6) as! NSDictionary)["short_name"] as! String
//                                }
//                                newaddress = "\(number) \(street), \(city), \(state) \(zip)"
//                                print(newaddress)
//
//                                // OR
//                                //This is second type to fetch pincode, country, state like this type of data
//
//                                for i in 0..<address.count {
//                                    print(((address.object(at: i) as! NSDictionary)["types"] as! Array)[0])
//                                    if ((address.object(at: i) as! NSDictionary)["types"] as! Array)[0] == "postal_code" {
//                                        zip =  (address.object(at: i) as! NSDictionary)["short_name"] as! String
//                                    }
//                                    if ((address.object(at: i) as! NSDictionary)["types"] as! Array)[0] == "country" {
//                                        country =  (address.object(at: i) as! NSDictionary)["long_name"] as! String
//                                    }
//                                    if ((address.object(at: i) as! NSDictionary)["types"] as! Array)[0] == "administrative_area_level_1" {
//                                        state =  (address.object(at: i) as! NSDictionary)["long_name"] as! String
//                                    }
//                                    if ((address.object(at: i) as! NSDictionary)["types"] as! Array)[0] == "administrative_area_level_2" {
//                                        district =  (address.object(at: i) as! NSDictionary)["long_name"] as! String
//                                    }
//
//                                }
//                                print(city)
//
//                            }
//
//                        }
//                    }
//
//                }
//
//            }
//
//        }
//
//    }
}
