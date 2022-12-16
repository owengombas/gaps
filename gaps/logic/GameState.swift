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
    private var _parent: GameState? = nil
    
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
    
    /**
     Is the GameState final and solved
     */
    var isSolved: Bool {
        get { return self.misplacedCards() == 0 }
    }
    
    /**
     Does this state has possible moves ?
     */
    var isLeaf: Bool {
        get { return self._moves.count <= 0 }
    }

    /**
     Get the score of the game state
     */
    var score: Int {
        get { return self.misplacedCards() }
    }
    
    /**
     The parent GameState that generated the current state
     */
    var parent: GameState? {
        get { return self._parent }
        set { self._parent = newValue }
    }
    
    convenience init() {
        self.init(columns: 13, rows: 4)
    }
    
    init(columns: Int, rows: Int) {
        assert((1...13).contains(columns), "Columns must be in [1, 13]")
        assert((1...4).contains(rows), "Rows must be in [1, 4]")
        
        super.init(
            columns: columns,
            rows: rows,
            defaultValue: { (_, _, c, m) in
                return Card.fromNumber(number: c, columns: m.columns)
            }
        )
    }
    
    /**
     Get a copy of the actual state
     */
    override func copy() -> GameState {
        let s = GameState()
        
        s.setElements(value: {(i, j, _, _) in
            return self.getElement(column: i, row: j)
        })
        
        return s
    }
    
    /**
     Copy and apply the GameState passed in the from parameter to the current one
     */
    func copy(from: GameState) {
        super.copy(from: from)
        
        DispatchQueue.main.async {
            self._removedCards = from.removedCards
            self._moves = from.moves
        }
    }
    
    /**
     Reset and rearrange the game to it's initial state
     */
    override func reset() {
        super.reset()
        
        self._moves = []
        self._removedCards = []
    }
    
    /**
     Return the path from the root state to the current one as an array
     */
    func rewind() -> [GameState] {
        var states: [GameState] = []
        var currentState: GameState = self

        while currentState.parent != nil {
            states.insert(currentState, at: 0)
            currentState = currentState.parent!
        }

        return states
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
    func remove(_ cardRank: CardRank) {
        self.forEach {i, j, v, c, m in
            if v?.rank == cardRank {
                self.setElement(i: i, j: j, value: nil)
                self._removedCards.append(v!)
            }
        }
    }
    
    /**
     Remove one card randomly
     */
    func removeRandomly() -> (Int, Int) {
        var card: Card? = nil
        var pos: (Int, Int)? = nil
        
        while card === nil {
            let posIndex = Int.random(in: 0..<self.capacity)
            pos = self.getPositionFrom(index: posIndex)
            
            card = self.getElement(position: pos!)
        }
        
        self.setElement(position: pos!, value: nil)
        self._removedCards.append(card!)
        
        return pos!
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
     Generate all moves for a specific card rank to a specific position
     */
    private func getMovesFor(cardRank: CardRank, emptySpace: (Int, Int)) -> [Move] {
        var acesMoves: [Move] = []
        
        self.forEach {i, j, c, v, m in
            if (c?.rank == cardRank) {
                let childrenState: GameState = self.copy()
                childrenState.parent = self
                childrenState.swap(posA: (i, j), posB: emptySpace)
                
                let move = Move(
                    from: (i, j),
                    to: emptySpace,
                    card: c!,
                    state: childrenState,
                    parentState: self
                )
                
                acesMoves.append(move)
            }
        }
        
        return acesMoves
    }
    
    /**
    Find all moves based on the game rules
     */
    func computeMoves() {
        DispatchQueue.main.async {
            self._moves = []
        }
        
        for gap in gaps {
            // Get the previous card in the game state
            let leftCard: Card? = self.previous(position: gap)
            if leftCard == nil {
                // If the gap is at the begining of a row, then all aces can fill it
                if gap.0 <= 0 {
                    DispatchQueue.main.async {
                        self._moves.append(contentsOf: self.getMovesFor(cardRank: .ACE, emptySpace: gap))
                    }
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
            childrenState.parent = self
            childrenState.swap(posA: gap, posB: higherLeftCardPosition!)
            
            let m = Move(
                from: higherLeftCardPosition!,
                to: gap,
                card: higherLeftCard!,
                state: childrenState,
                parentState: self
            )
            
            DispatchQueue.main.async {
                self._moves.append(m)
            }
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
            if move.to.0 == 0 && move.card.rank == .ACE {
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
            if !self.verifyMove(move: move) {
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
            return self.getElement(column: i - 1, row: j)
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
            return self.getElement(column: i + 1, row: j)
        }
        return nil
    }

    /**
    Get the number of misplaced cards
     */
    func misplacedCards() -> Int {
        var count = 0

        for row in 0..<self.rows {
            let firstCard: Card? = self.getElement(column: 0, row: row)
            if firstCard === nil { continue }
        
            if firstCard!.rank != .ACE { continue }
            count += 1

            for column in 1..<self.columns {
                let card: Card? = self.getElement(column: column, row: row)

                if card === nil { break }
                if card!.suit != firstCard!.suit { break }
                if card!.rank.rawValue != column { break }
                
                count += 1
            }
        }

        return self.capacity - count
    }

    /**
     Is the GameState equals to an another one
     */
    func isEquals(to: GameState?) -> Bool {
        if to === nil {
            return false
        }
        
        for i in 0..<self.capacity {
            let cardA = self.getElement(number: i)
            let cardB = to!.getElement(number: i)

            if cardA?.number != cardB?.number {
                return false
            }
        }

        return true
    }

    /**
     Breadth first search
     */
    func bfs() -> GameState? {
        var queue: [GameState] = []
        var visited: [GameState] = []

        queue.append(self)

        while queue.count > 0 {
            let state = queue.removeFirst()

            if state.isSolved {
                return state
            }

            state.computeMoves()

            for move in state._moves {
                let newState = move.state
                newState.computeMoves()

                if !visited.contains(where: { state in
                    state.isEquals(to: newState)
                }) {
                    queue.append(newState)
                    visited.append(newState)
                }
            }
        }

        return nil
    }

    /**
     Branch and bound
     */
    func branchAndBound(maxClosed: Int = Int.max, onBetterStateFound: ((GameState) -> Void)? = nil) async -> GameState? {
        var queue: [GameState] = []
        var visited: [GameState] = []

        queue.append(self)
        var bestState: GameState = self.copy()

        while queue.count > 0 {
            let state = queue.removeFirst()

            if state.isSolved {
                return state
            } else if state.score < bestState.score {
                bestState = state
                onBetterStateFound?(bestState)
            }

            state.computeMoves()

            for move in state._moves {
                let newState = move.state
                newState.computeMoves()

                if !visited.contains(where: { state in
                    state.isEquals(to: newState)
                }) {
                    queue.append(newState)
                    visited.append(newState)
                }
                
                if visited.count >= maxClosed {
                    onBetterStateFound?(bestState)
                    return bestState
                }
            }
        }
        
        return bestState
    }
    
    /**
     A star algorithm
     */
    func astar(maxClosed: Int = Int.max, onBetterStateFound: ((GameState) -> Void)? = nil) async -> GameState? {
        var open: [GameState] = []
        var closed: [GameState] = []
        
        var bestState: GameState = self.copy()

        open.append(self)
        
        var i: Int = 0

        while open.count > 0 {
            let state = open.removeFirst()
            closed.append(state)

            if state.isSolved {
                bestState = state
                onBetterStateFound?(bestState)
                return state
            }

            state.computeMoves()

            for move in state._moves {
                let newState = move.state
                newState.computeMoves()
                
                if newState.isSolved {
                    return newState
                } else if newState.score < bestState.score {
                    bestState = newState
                    onBetterStateFound?(bestState)
                }
                
                if !closed.contains(where: { $0.isEquals(to: newState) }) {
                    open.append(newState)
                }
                
                if closed.count >= maxClosed {
                    onBetterStateFound?(bestState)
                    return bestState
                }
            }
            
            i += 1
        }
        
        return bestState
    }
}
