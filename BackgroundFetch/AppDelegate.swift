//
//  AppDelegate.swift
//  BackgroundFetch
//
//  Created by Anand Upadhyay on 07/06/24.
//

import UIKit
import BackgroundTasks
import UserNotifications
import CoreLocation

let TaskId = "com.anand.ios.BackgroundFetch.task.refresh"
let DateTimeArray = "LocationTime"
//Command to trigger Backgroun fetch
// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.anand.ios.BackgroundFetch.task.refresh"]
let APPDELEGATE = (UIApplication.shared.delegate as! AppDelegate)

@main
class AppDelegate: UIResponder, UIApplicationDelegate,CLLocationManagerDelegate {

    var locationManager:CLLocationManager!
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .long
        return formatter
      }()

      var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setupLocationmanager()
        
        
        // Override point for customization after application launch.
        BGTaskScheduler.shared.register(
          forTaskWithIdentifier: TaskId, using: nil) { task in
            self.refresh()
            task.setTaskCompleted(success: true)
            self.scheduleAppRefresh()
        }
        printTimeArray()
        scheduleAppRefresh()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    
    func applicationDidEnterBackground(_ application: UIApplication){
        print("Move to Background")
    }
}


extension AppDelegate{
    func refresh(){
      // to simulate a refresh, just update the last refresh date
      // to current date/time
      let formattedDate = Self.dateFormatter.string(from: Date())
      var timeArray = UserDefaults.standard.array(forKey: DateTimeArray) as? [String] ?? []
        timeArray.append(formattedDate)
      UserDefaults.standard.set(
        timeArray,
        forKey: DateTimeArray)
        printTimeArray()
    }
    
    func printTimeArray(){
        let timeArray = UserDefaults.standard.array(forKey: DateTimeArray) as? [String] ?? []
        print("Date time Array:\(timeArray)")
    }
   
    func scheduleAppRefresh() {
      let request = BGAppRefreshTaskRequest(
        identifier: TaskId)
      request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60)
      do {
        try BGTaskScheduler.shared.submit(request)
        print("background refresh scheduled")
      } catch {
        print("Couldn't schedule app refresh \(error.localizedDescription)")
      }
    }
}


extension AppDelegate{
    
    func setupLocationmanager(){
        
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest//kCLLocationAccuracyBestForNavigation//kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()//added 9 Dec 2023
        locationManager.activityType = .other//9 Dec 2023
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false//added on 4 June 2024
//        self.backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DummyTask", expirationHandler: {
//            NSLog("Background task expired by iOS.")
//            UIApplication.shared.endBackgroundTask(self.backgroundTask)
//      })
        
        var lastLogTime = 0.0
        DispatchQueue.global().async {
            let startedTime = Int(Date().timeIntervalSince1970) % 10000000
            NSLog("*** STARTED BACKGROUND THREAD")
            while(true){
                DispatchQueue.main.async {
                    let now = Date().timeIntervalSince1970
                    let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
                    if abs(now - lastLogTime) >= 2.0 {
                        lastLogTime = now
                        if backgroundTimeRemaining < 10.0 {
                            NSLog("About to suspend based on background thread running out.")
                        }
                        if (backgroundTimeRemaining < 200000.0) {
                            NSLog("Thread \(startedTime) background time remaining: \(backgroundTimeRemaining)")
                        }
                        else {
                            //NSLog("Thread \(startedTime) background time remaining: INFINITE")
                        }
                    }
                }
                sleep(1)
            }
//            print("*** EXITING BACKGROUND THREAD")
        }
        // = = = = = //
    }
    
    func postNotificatin(msg: String)
    {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()

        content.title = AddMoreOptions.appName.title
        content.subtitle = msg
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest.init(identifier: "notificationid", content: content, trigger: trigger)
        center.add(request) { (error) in
            if (error != nil){
                print("Error sending notificaiton: \(String(describing: error)) didDetermineState ")
            }
        }
    }
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
//        print("locations = \(locValue.latitude) \(locValue.longitude)")
//        if APPDELEGATE.geofenceRegion != nil {
//            locationManager.requestState(for: geofenceRegion)
//        }
//    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion){
        manager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint){
//        print("Ranged beacons: \(beacons.count) didRange")
    }
    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
//        Print.Print("locationManager error: \(error.localizedDescription) didFailWithError",isPrint: false)
//    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error){
        Print.Print("locationManager monitoring failure error: \(error.localizedDescription) monitoringDidFailFor",isPrint: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        Print.Print("enter didEnterRegion:\(region.identifier)",isPrint: false)
//        if isMonitoring(idd: identifierBeacon){
//            postNotificatin(msg: "In the Region \(region.identifier)")
            handleEvent(region: region)
//        }
//        handleEvent(forRegion: region, msg: "In the Region")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion){
        Print.Print("exit didExitRegion:\(region.identifier)",isPrint: false)
        //check if region is our Device Monitoring Region then get new location  and if distance between previously monitored location is greater then deicded then monitor new region and also update to api
        if region.identifier == MyDeviceRegionMonitoryKey{
            checkLastLocationAndMonitorCurrentlocation()
        }else{
            handleEvent(region: region)
        }
//        }
//        handleEvent(forRegion: region, msg: "Outside the Region")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion){
        Print.Print("didDetermineState:\(region.identifier) : \(state)",isPrint: false)
        //comment this code to make notification fired only once 15 Dec 20123
        //        var stateString = "Unknow"
        //        if state == .inside {
        //            stateString = "In the Region \(region.identifier)"
        //            if isMonitoring(idd: identifierBeacon){
        //                postNotificatin(msg: stateString)
        //            }
        //        }
//        handleEvent(region: region)
        //        else if state == .outside {
        //            stateString = "Outside the Region \(region.identifier)"
        //            if isMonitoring(idd: identifierBeacon){
        //                postNotificatin(msg: stateString)
        //            }
        //        }else{
        //
        //        }
        //    }
    }
}

extension AppDelegate{
    
    func checkLastLocationAndMonitorCurrentlocation(){
        
        let alredyMonitoring = LocationManager.shared.isRegionAlreadyRegistered(identifier: MyDeviceRegionMonitoryKey)
        Print.Print("Monitoring:\(alredyMonitoring)",isPrint: true)
        let lastLocation = locationManager.location
        let newLat = Double(lastLocation?.coordinate.latitude ?? 0.0)
        let newLon = Double(lastLocation?.coordinate.longitude ?? 0.0)
        let locationUpdated = LocationPoint(latitude: newLat, longitude: newLon)
        let locationMapLast: [String: Any] =  LatLonManager.shared.getLastSavedMyLocation()
        var loctionPrev:LocationPoint = LocationPoint(latitude: 0, longitude: 0)
        var updatedLocationMap = false
        if locationMapLast.count > 0{
            //Calculate Distance if its greater based posting
            let prevLat = locationMapLast["lat"] as? Double ?? 0
            let prevLon = locationMapLast["lon"] as? Double ?? 0
            loctionPrev = LocationPoint(latitude: prevLat, longitude: prevLon)
            let distance = LatLonManager.shared.differenceInMeters(loc1: loctionPrev, loc2: locationUpdated)
            Print.Print("Distance: \(distance)", isPrint: true)
            if (distance >= MyDeviceRegionMonitorRadius){
                updatedLocationMap = true
            }
        }else{
            updatedLocationMap = true
        }
        
        //check if need to update then do update location and call api
        if updatedLocationMap{
            addDeviceRegionMonitor(updatedLocation: locationUpdated,prev: loctionPrev)
        }
    }
    
    func addDeviceRegionMonitor(updatedLocation: LocationPoint,prev: LocationPoint){
        if APPDELEGATE.IsLocationAccessible {
            //If already monitoring then remove region and then monitor new region
            let alredyMonitoring = LocationManager.shared.isRegionAlreadyRegistered(identifier: MyDeviceRegionMonitoryKey)
            if alredyMonitoring
            {
                LocationManager.shared.deleteRegionMonitorForMyDevice(latitude: prev.latitude, longitude: prev.longitude, identifier: MyDeviceRegionMonitoryKey,radius: MyDeviceRegionMonitorRadius)
            }
            let result = LocationManager.shared.monitorMyDeviceRegion(latitude: updatedLocation.latitude, longitude: updatedLocation.longitude, identifier: MyDeviceRegionMonitoryKey, passType: .generic, maxDistance: MyDeviceRegionMonitorRadius)
            if result {
                //need to update Location only if able to monitor new region
                UserDefaults.standard.setValue(["lat":updatedLocation.latitude,"lon":updatedLocation.longitude,"timestamp":LatLonManager.shared.formatDate(Date())], forKey: UserDefaultKeys.MyDeviceMonitoredLocation.rawValue)
                let timestamp = Date()
                let apiManager : APIService = APIService()
                let apiURL = AppURL.UpdateUserLocationUrl.rawValue
                
                let parameters = ["a":"2","b":updatedLocation.latitude,"c":updatedLocation.longitude,"d":LatLonManager.shared.formatDate(timestamp)] as [String : Any]
                apiManager.updateLocationToServer(requestType: .post, apiUrl: apiURL, parameters: parameters){ success, dictionary in
                    Print.Print("Posting Location :\(String(describing: dictionary))",isPrint: true)
                }
            }
        }
    }
}

