//
//  pop_upApp.swift
//  pop-up
//
//  Created by Jiaye Fang on 8/10/25.
//

import SwiftUI

@main
struct pop_upApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
