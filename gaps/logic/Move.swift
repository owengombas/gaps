//
//  Move.swift
//  gaps
//
//  Created by owen on 19.10.22.
//

import Foundation

/**
 Represents a move in the game
 */
class Move: CustomStringConvertible {
    var description: String {
        get {
            return "MOVE CARD \(self.card.description) FROM \(self.from) TO \(self.to)"
        }
    }
    
    private var _from: (Int, Int)
    private var _to: (Int, Int)
    private var _card: Card
    private var _state: GameState
    
    var from: (Int, Int) {
        get { return self._from }
    }
    
    var to: (Int, Int) {
        get { return self._to }
    }
    
    var state: GameState {
        get { return self._state }
    }
    
    var card: Card {
        get { return self._card }
    }
    
    init(from: (Int, Int), to: (Int, Int), card: Card, state: GameState) {
        self._from = from
        self._to = to
        self._card = card
        self._state = state
    }
}
