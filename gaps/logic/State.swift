//
//  Game.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class State: Matrix<Card?> {
    private var _emptySpaces: [(Int, Int)] = []
    
    var emptySpaces: [(Int, Int)]  {
        get { return self._emptySpaces }
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
    
    func removeRandomly() -> Int {
        var toRemove: Card? = nil
        var posIndex: Int = -1
        
        while toRemove == nil {
            let newPosNumber = Int.random(in: 0..<self.capacity)
            
//            let newPos = getPositionFrom(index: newPosNumber)
//
//            let prevElement: Card? = self.getElement(i: newPos.0 + 1, j: newPos.1)
//            let nextElement: Card? = self.getElement(i: newPos.0 - 1, j: newPos.1)
//
//            acceptable = (
//                prevElement != nil &&
//                nextElement != nil
//            )
                
            posIndex = newPosNumber
            
            toRemove = self.getElement(number: posIndex)
        }
        
        self.setElement(number: posIndex, value: nil)
        self._emptySpaces.append(self.getPositionFrom(index: posIndex))
        
        return posIndex
    }
    
    func removeRandomlyNCards(n: Int) {
        for _ in 0..<n {
            let _ = removeRandomly()
        }
    }
    
    func computeChildrenStates() -> [State] {
        var children: [State] = []
        
        for emptySpace in emptySpaces {
            let previousPositionCard: Card? = self.previous(position: emptySpace)
            
            if previousPositionCard == nil {
                print("NO PREVIOUS POSITION CARD FOR \(emptySpace)")
                continue
            }
            
            let foundPosition = self.find(card: previousPositionCard!.next)
            if foundPosition == nil {
                print("NO NEXT CARD FOR \(previousPositionCard!)")
                continue
            }
            
            let childrenState: State = self.copy()
            print ("MOVING \(self.getElement(position: foundPosition!)) (position: \(foundPosition!)) NEXT TO \(previousPositionCard!) (to position: \(emptySpace))")
            childrenState.swap(from: emptySpace, to: foundPosition!)
            children.append(childrenState)
        }
        
        return children
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
            if v == nil { return false }
            if v!.isEquals(to: card) { return true }
            
            return false
        })
    }
}
