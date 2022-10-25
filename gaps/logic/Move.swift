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
            return "MOVE CARD \(self.card.description) FROM (\(self.from.1 + 1), \(self.from.0 + 1)) TO (\(self.to.1 + 1), \(self.from.0 + 1))"
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
    
    init(card: Card, to: (Int, Int), state: GameState) {
        self._from = state.find(card: card)!
        self._to = to
        self._card = card
        self._state = state
    }
}
