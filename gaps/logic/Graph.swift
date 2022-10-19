//
//  Graph.swift
//  gaps
//
//  Created by owen on 17.10.22.
//

import Foundation

class Graph<T> {
    private var _children: [Graph<T>]
    
    init() {
        self._children = []
    }
}
