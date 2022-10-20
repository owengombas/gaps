//
//  Game.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class State: Matrix<Card?> {
    @Published private var _moves: [Move] = []
    private var _emptySpaces: [(Int, Int)] = []
    
    var emptySpaces: [(Int, Int)]  {
        get { return self._emptySpaces }
    }
    
    var moves: [Move] {
        get { return self._moves }
    }
    
    init() {
        super.init(
            columns: 13,
            lines: 4,
            defaultValue: {(_, _, c) in
                return Card.fromNumber(number: c)
            }
        )
    }
    
    override func copy() -> State {
        let s = State()
        s._emptySpaces = self.emptySpaces
        
        s.setElements(value: {(i, j, _, _) in
            return self.getElement(i: i, j: j)
        })
        
        return s
    }
    
    func redistribute() {
        self._emptySpaces = []
        self._moves = []
        self.forEach(cb: {(i, j, v, c) in
            return self.setElement(i: i, j: j, value: Card.fromNumber(number: c))
        })
    }
    
    func removeRandomly(notAround: Int) -> Int {
        var toRemove: Card? = nil
        var posIndex: Int = -1
        
        while toRemove == nil || (notAround-1...notAround+1).contains(posIndex) {
            posIndex = Int.random(in: 0..<self.capacity)
            
            toRemove = self.getElement(number: posIndex)
        }
        
        self.setElement(number: posIndex, value: nil)
        self._emptySpaces.append(self.getPositionFrom(index: posIndex))
        
        return posIndex
    }
    
    func removeCardsRandomly(numberOfCards: Int) {
        var lastIndex: Int = Int.min + 1
        for _ in 0..<numberOfCards {
            lastIndex = removeRandomly(notAround: lastIndex)
        }
    }
    
    func computeMoves() {
        self._moves = []
        
        print(self)
        
        for emptySpace in emptySpaces {
            let previousPositionCard: Card? = self.previous(position: emptySpace)
            if previousPositionCard == nil { continue }
            
            let card = previousPositionCard!.next
            if card == nil { continue }
            
            let foundPosition = self.find(card: card)
            if foundPosition == nil { continue }
            
            let childrenState: State = self.copy()
            childrenState.swap(from: emptySpace, to: foundPosition!)
            
            let m = Move(from: foundPosition!, to: emptySpace, card: card!, state: childrenState)
            self._moves.append(m)
        }
    }
    
    func previous(position: (Int, Int)) -> Card? {
        return previous(i: position.0, j: position.1)
    }
    
    func previous(i: Int, j: Int) -> Card? {
        if i - 1 >= 0 {
            return self.getElement(i: i - 1, j: j)
        }
        return nil
    }
    
    func next(position: (Int, Int)) -> Card? {
        return next(i: position.0, j: position.1)
    }
    
    func next(i: Int, j: Int) -> Card? {
        if i + 1 <= self.columns - 1 {
            return self.getElement(i: i + 1, j: j)
        }
        return nil
    }
    
    func find(card: Card?) -> (Int, Int)? {
        return self.findOnePosition(condition: {(i: Int, j: Int, v: Card?, c: Int) in
            return v?.number == card?.number
        })
    }
}
