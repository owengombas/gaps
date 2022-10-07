//
//  Game.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class State {
    private var _cards: Matrix<State>
    
    init() {
        self._cards = Matrix(columns: 13, lines: 4)
    }
}
