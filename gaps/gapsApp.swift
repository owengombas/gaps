//
//  gapsApp.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import SwiftUI

@main
struct gapsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    static func main() throws {
        let s = State()
        s.removeRandomlyNCards(n: 4)
        print(s)
    }
}
