//
//  DiplomaApp.swift
//  Diploma
//
//  Created by Orest Palii on 31.03.2025.
//

import SwiftUI
import FirebaseCore
import FirebaseDatabase

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    Database.database().isPersistenceEnabled =  false
    Database.database().goOnline()
      
    return true
  }
}

@main
struct DiplomaApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AuthView()
        }
    }
}
