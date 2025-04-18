//
//  Lib1App.swift
//  Lib1
//
//  Created by admin100 on 16/04/25.
//

import SwiftUI
import FirebaseCore

@main
struct Lib1App: App {
    init() {
        FirebaseApp.configure() // Initialize Firebase
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SplashScreenView()
            }
        }
    }
}
