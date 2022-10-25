//
//  Game.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

/**
 Represent a game state
 */
class GameState: Matrix<Card?> {
    @Published private var _moves: [Move] = []
    private var _removedCards: [Card] = []
    
    /**
     The gapses positions
     */
    var gaps: [(Int, Int)]  {
        get {
            return self.findPositions(condition: {i, j, v, c in
                return v == nil
            })
        }
    }
    
    /**
     Get the state's possibles moves
     */
    var moves: [Move] {
        get { return self._moves }
    }
    
    /**
     The state's removed cards
     */
    var removedCards: [Card] {
        get { return self._removedCards }
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
    
    /**
     Get a copy of the actual state
     */
    override func copy() -> GameState {
        let s = GameState()
        
        s.setElements(value: {(i, j, _, _) in
            return self.getElement(i: i, j: j)
        })
        
        return s
    }
    
    /**
     Reset and rearrange the game to it's initial state
     */
    func reset() {
        self._moves = []
        self._removedCards = []
        self.forEach(cb: {(i, j, v, c) in
            return self.setElement(i: i, j: j, value: Card.fromNumber(number: c))
        })
    }
    
    /**
     Find a card position in the game
     */
    func find(card: Card?) -> (Int, Int)? {
        return self.findOnePosition(condition: {(i: Int, j: Int, v: Card?, c: Int) in
            return v?.number == card?.number
        })
    }
    
    /**
     Remove the king cards from the game
     */
    func removeKings() {
        self.forEach(cb: {i, j, v, c in
            if v?.cardNumber == .KING {
                self.setElement(i: i, j: j, value: nil)
                self._removedCards.append(v!)
            }
        })
    }
    
    /**
     Remove randomly one (NOT SAFE)
     */
    func removeRandomly() -> Int {
        var toRemove: Card? = nil
        var posIndex: Int = -1
        
        // Do not remove an already remove value
        while toRemove == nil {
            posIndex = Int.random(in: 0..<self.capacity)
            toRemove = self.getElement(number: posIndex)
        }
        
        self._removedCards.append(self.getElement(number: posIndex)!)
        self.setElement(number: posIndex, value: nil)
        
        return posIndex
    }
    
    /**
     Remove randomly N cards from the game
     */
    func removeCardsRandomly(numberOfCards: Int) {
        for _ in 0..<numberOfCards {
            let _ = self.removeRandomly()
        }
    }
    
    /**
     Generate all moves for a specific cardNumber to a specific position
     */
    private func getMovesFor(cardNumber: CardNumbers, emptySpace: (Int, Int)) -> [Move] {
        var acesMoves: [Move] = []
        
        self.forEach(cb: {i, j, c, v in
            if (c?.cardNumber == cardNumber) {
                let childrenState: GameState = self.copy()
                childrenState.swap(posA: (i, j), posB: emptySpace)
                
                let move = Move(from: (i, j), to: emptySpace, card: c!, state: childrenState)
                
                acesMoves.append(move)
            }
        })
        
        return acesMoves
    }
    
    /**
    Find all moves based on the game rules
     */
    func computeMoves() {
        self._moves = []
        
        for gap in gaps {
            // Get the previous card in the game state
            let leftCard: Card? = self.previous(position: gap)
            if leftCard == nil {
                // If the gap is at the begining of a row, then all aces can fill it
                if gap.0 <= 0 {
                    self._moves.append(contentsOf: getMovesFor(cardNumber: .ACE, emptySpace: gap))
                }
                continue
            }
            
            // Get the higher card from the left one
            let higherLeftCard = leftCard!.higher
            if higherLeftCard == nil {
                // print("NO HIGHER CARD FOR \(leftCard!) AT \(gap)")
                continue
                
            }
            
            // Get the position of the higher card from the left one in the current game state
            let higherLeftCardPosition = self.find(card: higherLeftCard)
            if higherLeftCardPosition == nil {
                // print("HIGHER CARD \(higherLeftCard!) POSITION NOT FOUND")
                continue
            }
            
            // Copy current state, move the card to the gap and add it to children moves
            let childrenState: GameState = self.copy()
            childrenState.swap(posA: gap, posB: higherLeftCardPosition!)
            
            let m = Move(from: higherLeftCardPosition!, to: gap, card: higherLeftCard!, state: childrenState)
            self._moves.append(m)
        }
    }
    
    /**
     Verify if a move is performable, if the user can move the card and mutate the state, relying on the game rules
     */
    func verifyMove(move: Move) -> Bool {
        let supposedGap = self.getElement(position: move.to)
        
        // If the destination isn't a gap, then the move isn't performable
        if supposedGap != nil {
            return false
        }
        
        let previousCard = self.previous(position: move.to)
        
        if previousCard == nil {
            // If the card is an ace and the user wants to move it at the beginning of a row, then it's movable
            if move.to.0 == 0 && move.card.cardNumber == .ACE {
                return true
            }
            
            // If there's no previous card then the move isn't performable
            return false
        }
        
        let higherPreviousCard = previousCard?.higher
        
        // If king, then no card can be placed in the gap
        if higherPreviousCard == nil {
            return false
        }
        
        // If the card isn't strictly one rank higher to the previous one then the move isn't performable
        if !higherPreviousCard!.isEquals(to: move.card) {
            return false
        }
        
        return true
    }
    
    /**
     Clear the moves
     */
    func clearMoves() {
        self._moves = []
    }
    
    /**
     Apply a move and change the current state
     */
    func performMove(move: Move, verify: Bool = false) {
        if verify == true {
            if !verifyMove(move: move) {
                return
            }
        }
        
        self.swap(posA: move.from, posB: move.to)
        self.computeMoves()
    }
    
    /**
     Get the possible moves for a specified card  (you have to perform computeMoves before)
     */
    func possibleMoves(card: Card) -> [Move] {
        return self._moves.filter({ move in
            return move.card.isEquals(to: card)
        })
    }
    
    /**
    Is the card in the moves, can the card be moved in a gap (you have to perform computeMoves before)
     */
    func isMovable(card: Card) -> Bool {
        return self.possibleMoves(card: card).count > 0
    }
    
    /**
     Get all the possible gaps where a card can be moved in  (you have to perform computeMoves before)
     */
    func possibleGaps(card: Card) -> [Move] {
        return self._moves.filter({ move in
            return self.getElement(position: move.to)!.isEquals(to: card)
        })
    }
    
    /**
     Can the card be moved inside a specified gap  (you have to perform computeMoves before)
     */
    func isAPossibleGap(card: Card?, gap: (Int, Int)) -> Bool {
        if card === nil {
            return false
        }
        
        for move in self._moves {
            if !move.card.isEquals(to: card) {
                continue
            }
            
            if move.to == gap {
                return true
            }
        }
        
        return false
    }
    
    func isAPossibleGap(card: Card?, gap: Int) -> Bool {
        return self.isAPossibleGap(card: card, gap: self.getPositionFrom(index: gap))
    }
    
    /**
     Get the previous Card in the game from a position
     */
    func previous(position: (Int, Int)) -> Card? {
        return self.previous(i: position.0, j: position.1)
    }
    
    /**
     Get the previous Card in the game from a position
     */
    func previous(i: Int, j: Int) -> Card? {
        if i - 1 >= 0 {
            return self.getElement(i: i - 1, j: j)
        }
        return nil
    }
    
    /**
     Get the next Card in the game from a position
     */
    func next(position: (Int, Int)) -> Card? {
        return self.next(i: position.0, j: position.1)
    }
    
    /**
     Get the next Card in the game from a position
     */
    func next(i: Int, j: Int) -> Card? {
        if i + 1 <= self.columns - 1 {
            return self.getElement(i: i + 1, j: j)
        }
        return nil
    }
}
