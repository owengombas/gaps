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
        print(s)
        print(s.toArray())
        
        print("\nSHUFFLING\n")
        
        s.shuffle()
        s.removeRandomlyNCards(n: 4)
        print(s)
        print(s.toArray())
        print(s.emptySpaces)
        print(s.computeChildrenStates())
    }
}
