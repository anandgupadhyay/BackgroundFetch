//
//  AppDelegate.swift
//  BackgroundFetch
//
//  Created by Anand Upadhyay on 07/06/24.
//

import UIKit
import BackgroundTasks

let TaskId = "com.anand.ios.BackgroundFetch.task.refresh"
let DateTimeArray = "LocationTime"
//Command to trigger Backgroun fetch
// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.anand.ios.BackgroundFetch.task.refresh"]
let APPDELEGATE = (UIApplication.shared.delegate as! AppDelegate)

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .long
        return formatter
      }()

      var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
