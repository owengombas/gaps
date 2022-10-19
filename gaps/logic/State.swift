//
//  Game.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class State: CustomStringConvertible {
    var description: String {
        get {
            return String(describing: self._cards)
        }
    }
    
    private var _cards: Matrix<Card>
    private var _columns = 13
    private var _lines = 4
    
    var columns: Int {
        get { return self._columns }
    }
    
    var lines: Int {
        get { return self._columns }
    }
    
    var capacity: Int {
        get { return self._columns * self._lines }
    }
    
    var card: Matrix<Card> {
        get { return self._cards }
    }
    
    init() {
        self._cards = Matrix(columns: self._columns, lines: self._lines)
        
        self._cards.map(cb: {(i, j, v, c) in
            return Card.fromNumber(number: c)
        })
    }
    
    func shuffle() {
        for i in 0..<self.capacity {
            let j = Int.random(in: i..<self.capacity)
            
            let iPos: (Int, Int) = self._cards.getIJPosition(from: i)
            let jPos: (Int, Int) = self._cards.getIJPosition(from: j)
            
            self._cards.swap(i1: iPos.0, j1: iPos.1, i2: jPos.0, j2: jPos.1)
        }
    }
    
    func removeRandomly() -> Int {
        var toRemove: Card? = nil
        var pos: Int = -1
        
        while toRemove == nil {
            pos = Int.random(in: 0..<self.capacity)
            toRemove = self._cards.getElement(number: pos)
        }
        
        self._cards.setElement(number: pos, value: nil)
        
        return pos
    }
    
    func removeRandomlyNCards(n: Int) {
        for _ in 0..<n {
            let _ = removeRandomly()
        }
    }
}
