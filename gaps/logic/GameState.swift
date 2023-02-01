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
class GameState: Matrix<Card?>, Hashable {
    private var _removedCards: [Card] = []
    private var _parent: GameState? = nil
    private var _gScore: Int = 0
    private var _fScore: Int = 0
    private var _hScore: Int = 0

    /**
     The seed of the game
     */
    var seed: String {
        get {
            let padding = { (n: Int) in
                String(format: "%02d", n)
            }

            var seed: String = padding(self.rows) + padding(self.columns)

            for i in 0 ..< self.rows {
                for j in 0 ..< self.columns {
                    let card = self.getElement(column: j, row: i)

                    var strRep = ""

                    if card === nil {
                        strRep = "XX"
                    } else {
                        strRep = padding(card!.toNumber(columns: self.columns))
                    }

                    seed += strRep
                }
            }

            return seed
        }
    }

    /**
     The computed gScore of the game
     */
    var gScore: Int {
        get {
            return self._gScore
        }
    }

    /**
     The computed fScore of the game
     */
    var fScore: Int {
        get {
            return self._fScore
        }
    }

    /**
     The computed hScore of the game (the heuristic value)
     */
    var hScore: Int {
        get {
            return self._hScore
        }
    }

    /**
     The max card rank of the game
     */
    var maxRank: CardRank {
        get {
            return CardRank.init(rawValue: self.columns - 1)!
        }
    }

    /**
     The state's removed cards
     */
    var removedCards: [Card] {
        get {
            return self._removedCards
        }
    }

    /**
     Does this state has possible moves ?
     */
    var isLeaf: Bool {
        get {
            return self.getMoves().count <= 0
        }
    }
    
    /**
     Is the GameState final and solved
     */
    var isSolved: Bool {
        get {
            return self.countMisplacedCards() == 0
        }
    }

    /**
     The parent GameState that generated the current state
     */
    var parent: GameState? {
        get {
            return self._parent
        }
        set {
            self._parent = newValue
        }
    }
    
    /**
     Get the cards of the game (flatten), use values to get cards as a matric
     */
    var cards: [Card?] {
        get {
            return self.values.flatMap { card in
                return card
            }
        }
    }

    /**
     Initialize a game state with 13 columns and 4 rows
     */
    convenience init() {
        self.init(columns: 13, rows: 4)
    }

    /**
     Initialize a game state with a specific number of columns and rows
     - Parameters:
       - columns: the number of columns
       - rows: the number of rows
     */
    init(columns: Int, rows: Int) {
        assert((1...13).contains(columns), "Columns must be in [1, 13]")
        assert((1...4).contains(rows), "Rows must be in [1, 4]")

        super.init(
                columns: columns,
                rows: rows,
                defaultValue: { (_, _, c, m) in
                    return Card.fromNumber(number: c, columns: m.columns, rows: m.rows)
                }
        )
    }

    /**
     Initialize a game state with a seed
     - Parameter seed: the seed
     */
    init(seed: String) {
        super.init(columns: 0, rows: 0, defaultValue: { _, _, _, _ in return nil })
        let _ = self.loadSeed(seed: seed)
    }

    /**
     Get a copy of the current state
     */
    override func copy() -> GameState {
        let s = GameState(columns: self.columns, rows: self.rows)

        s.setElements(value: { (i, j, _, _) in
            return self.getElement(column: i, row: j)
        })
        
        s.parent = self._parent
        s._removedCards = self._removedCards
        s._gScore = self.gScore
        s._fScore = self._fScore
        s._hScore = self._hScore

        return s
    }

    /**
     Copy and apply the GameState passed in the from parameter to the current one
     */
    func copy(from: GameState) {
        super.copy(from: from)

        self._removedCards = from.removedCards
        self._parent = from.parent
        self._gScore = from.gScore
        self._fScore = from._fScore
        self._hScore = from._hScore
    }

    /**
     Reset and rearrange the game to it's initial state
     */
    override func reset() {
        super.reset()

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
     The gaps positions
     */
    func getGaps() -> [(Int, Int)] {
        return self.findPositions(condition: { i, j, v, c in
            return v == nil
        })
    }

    /**
     Is the card at the given position a gap ?
     - Parameters:
       - column: the column
       - row: the row
     - Returns: true if the card is a gap, false otherwise
     */
    func isGap(column: Int, row: Int) -> Bool {
        return self.getElement(column: column, row: row) == nil
    }


    /**
     Is the card at the given position a gap ?
     - Parameters:
         - position: the position
     - Returns: true if the card is a gap, false otherwise
     */
    func isGap(position: (Int, Int)) -> Bool {
        return self.isGap(column: position.0, row: position.1)
    }

    /**
     Find a card position in the game
     - Parameters:
        - card: the card to find
     - Returns: the card position if found, nil otherwise
     */
    func find(card: Card?) -> (Int, Int)? {
        return self.findOnePosition(condition: { (i: Int, j: Int, v: Card?, c: Int) in
            return v?.toNumber(columns: self.columns) == card?.toNumber(columns: self.columns)
        })
    }

    /**
     Load a seed and rearrange the game
     - Parameter seed: the seed
     - Returns: True if the seed is valid, false otherwise
     */
    func loadSeed(seed: String) -> Bool {
        if seed.count < 4 {
            return false
        }
        
        var index = seed.startIndex ..< seed.index(seed.startIndex, offsetBy: 2)
        let rows = Int(seed[index])
        index = seed.index(seed.startIndex, offsetBy: 2) ..< seed.index(seed.startIndex, offsetBy: 4)
        let columns = Int(seed[index])
        
        if rows == nil || columns == nil {
            return false
        }
        
        if seed.count < rows! * columns! * 2 + 4 {
            return false
        }
        
        self.rows = rows!
        self.columns = columns!
        
        let tempState = self.copy()

        for row in 0 ..< tempState.rows {
            for column in 0 ..< tempState.columns {
                let number = row * tempState.columns + column

                index = seed.index(seed.startIndex, offsetBy: 4 + (number * 2)) ..< seed.index(seed.startIndex, offsetBy: 4 + (number * 2) + 2)
                let value = String(seed[index])

                if value == "XX" {
                    tempState.setElement(column: column, row: row, value: nil)
                } else {
                    let intValue = Int(value)
                    if intValue != nil {
                        tempState.setElement(column: column, row: row, value: Card.fromNumber(number: intValue!, columns: self.columns, rows: self.rows))
                    } else {
                        return false
                    }
                }
            }
        }
        
        self.copy(from: tempState)

        self._removedCards = tempState.findMissingCards()
        
        return true
    }

    /**
     Find the missing cards in the game, what cards are the ones that are not in the game (gaps)
     - Returns: the missing cards
     */
    func findMissingCards() -> [Card] {
        let currentSet: Set<Card?> = Set(self.cards)
        var fullSet: Set<Card?> = Set(GameState(columns: self.columns, rows: self.rows).cards)

        for card in currentSet {
            fullSet.remove(card)
        }

        return Array(fullSet.map { $0! })
    }

    /**
     Remove cards with a specific rank
     - Parameter cardRank: the rank
     */
    func remove(_ cardRank: CardRank) {
        self.forEach { i, j, v, c, m in
            if v?.rank == cardRank {
                self.setElement(column: i, row: j, value: nil)
                self._removedCards.append(v!)
            }
        }
    }

    /**
     Remove the last cards of the game (the one with the highest rank)
     */
    func removeLastCards() {
        self.remove(CardRank(rawValue: self.columns - 1)!)
    }

    /**
     Generate all moves for a specific card rank to a specific position
     - Parameters:
        - gap: the gap position
        - condition: the condition to apply to the card
     */
    private func getMovesFor(gap: (Int, Int), condition: (Card?) -> Bool) -> [Move] {
        var acesMoves: [Move] = []

        self.forEach { i, j, count, value, matrix in
            if condition(count) {
                let childrenState: GameState = self.copy()
                childrenState.parent = self
                childrenState.swap(posA: (i, j), posB: gap)

                let move = Move(
                        from: (i, j),
                        to: gap,
                        card: count!,
                        state: childrenState,
                        parentState: self
                )

                acesMoves.append(move)
            }
        }

        return acesMoves
    }

    /**
    Generate all moves (children) of the current game
     - Returns: An array of Move
     */
    func getMoves() -> [Move] {
        let moves = self.getGaps().reduce(into: []) { (moves: inout [Move], gap: (Int, Int)) in
            // If the gap is at the beginning of a row, then all aces can fill it
            if gap.0 <= 0 {
                moves.append(contentsOf: self.getMovesFor(gap: gap) { card in
                    card?.rank == .ACE
                })
                return
            }

            // Get the previous card in the game state
            let leftCard: Card? = self.previous(position: gap)
            if leftCard == nil {
                // self._moves.append(contentsOf: self.getMovesFor(gap: gap) { card in
                //    card != nil
                // })
                return
            }

            // Get the higher card from the left one
            let higherLeftCard = leftCard!.higher
            if higherLeftCard == nil {
                // print("NO HIGHER CARD FOR \(leftCard!) AT \(gap)")
                return

            }

            // Get the position of the higher card from the left one in the current game state
            let higherLeftCardPosition = self.find(card: higherLeftCard)
            if higherLeftCardPosition == nil {
                // print("HIGHER CARD \(higherLeftCard!) POSITION NOT FOUND")
                return
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

            moves.append(m)
        }

        return moves
    }

    /**
     Verify if a move is performable, if the user can move the card and mutate the state, relying on the game rules
     - Parameter move: The move to perform
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
     Apply a move and change the current state
     - Parameter move: The move to apply
     - Parameter verify: If true, the move will be verified before applying it (if the rules are respected)
     */
    func performMove(move: Move, verify: Bool = false) -> GameState {
        if verify == true {
            if !self.verifyMove(move: move) {
                return self
            }
        }

        self.swap(posA: move.from, posB: move.to)
        
        return self
    }

    /**
     Get the possible moves for a specified card (you have to perform computeMoves before)
     - Parameter card: The card to get the moves for
     */
    func possibleMoves(card: Card) -> [Move] {
        return self.getMoves().filter({ move in
            return move.card.isEquals(to: card)
        })
    }

    /**
     Is the card in the moves, can the card be moved in a gap (you have to perform computeMoves before)
     - Parameter card: The card to check
     */
    func isMovable(card: Card) -> Bool {
        return self.possibleMoves(card: card).count > 0
    }

    /**
     Get all the possible gaps where a card can be moved in (you have to perform computeMoves before)
     - Parameter card: The card to move
     */
    func possibleGaps(card: Card) -> [Move] {
        return self.getMoves().filter({ move in
            return self.getElement(position: move.to)!.isEquals(to: card)
        })
    }

    /**
     Can the card be moved inside a specified gap (you have to perform computeMoves before)
     - Parameter card: The card to move
     - Parameter gap: The position of the gap where the card can be moved
     */
    func isAPossibleGap(card: Card?, gap: (Int, Int)) -> Bool {
        if card === nil {
            return false
        }

        for move in self.getMoves() {
            if !move.card.isEquals(to: card) {
                continue
            }

            if move.to == gap {
                return true
            }
        }

        return false
    }

    /**
     Can the card be moved inside a specified gap (you have to perform computeMoves before)
     - Parameter card: The card to move
     - Parameter gap: The gap position (flatten) where the card can be moved
     */
    func isAPossibleGap(card: Card?, gap: Int) -> Bool {
        return self.isAPossibleGap(card: card, gap: self.getPositionFrom(index: gap))
    }

    /**
     Get the previous Card in the game from a position
     - Parameter position: The position of the card
     */
    func previous(position: (Int, Int)) -> Card? {
        return self.previous(i: position.0, j: position.1)
    }

    /**
     Get the previous Card in the game from a position
     - Parameter i: Column
     - Parameter j: Row
     */
    func previous(i: Int, j: Int) -> Card? {
        if i - 1 >= 0 {
            return self.getElement(column: i - 1, row: j)
        }
        return nil
    }

    /**
     Get the next Card in the game from a position
     - Parameter position: The position of the card
     */
    func next(position: (Int, Int)) -> Card? {
        return self.next(i: position.0, j: position.1)
    }

    /**
     Get the next Card in the game from a position
     - Parameter i: Column
     - Parameter j: Row
     */
    func next(i: Int, j: Int) -> Card? {
        if i + 1 <= self.columns - 1 {
            return self.getElement(column: i + 1, row: j)
        }
        return nil
    }

    /**
     Get the number of misplaced cards
     - Returns: The number of misplaced cards
     */
    func countMisplacedCards() -> Int {
        var count = 0

        // If the game didn't start yet, then there's no gap, so no misplaced card for them
        if self.removedCards.count <= 0 {
            count += self.rows
        }

        for row in 0..<self.rows {
            // If last card is a gap then +1, but only if the game started and that there's a removed card
            if self.removedCards.count > 0 {
                let lastCard: Card? = self.getElement(column: self.columns - 1, row: row)
                if lastCard === nil {
                    count += 1
                }
            }

            // If first card is an ace, skip the row
            let firstCard: Card? = self.getElement(column: 0, row: row)
            if firstCard?.rank != .ACE {
                continue
            }
            count += 1

            for column in 1..<self.columns-1 {
                let card: Card? = self.getElement(column: column, row: row)
                
                if card?.suit != firstCard?.suit {
                    continue
                }

                if card?.rank.rawValue != column {
                    continue
                }

                count += 1
            }
        }

        return self.capacity - count
    }

    /**
     Is the GameState equals to an another one
     - Parameters:
        - to: The GameState to compare
     - Returns: True if the two states are equals, false otherwise
     */
    func isEquals(to: GameState?) -> Bool {
        if self.capacity != to?.capacity {
            return false
        }
        
        if to === nil {
            return false
        }

        for i in 0..<self.capacity {
            let cardA = self.getElement(number: i)
            let cardB = to!.getElement(number: i)

            if cardA?.toNumber(columns: self.columns) != cardB?.toNumber(columns: self.columns) {
                return false
            }
        }

        return true
    }

    /**
     Depth first search: insert the state at the beginning of the list (queue.insert(0, state))
     Breadth first search: insert the state at the end of the list (queue.append(state))
     - Parameters:
        - insert: the function to insert the state in the queue
        - onClosedAdded: callback when a state is added to the closed list
        - onBetterStateFound: callback when a better state is found
        - maxClosed: maximum number of states in the closed list
     - Returns: the best state found
     */
    func generalizedSearch(
            insert: (inout [GameState], inout GameState) -> Void,
            onClosedAdded: ((Int) -> Void)? = nil,
            onBetterStateFound: ((GameState, Int) -> Void)? = nil,
            maxClosed: Int? = nil
    ) async -> GameState? {
        var bestState: GameState = self
        var bestScore: Int = self.countMisplacedCards()

        var queue: [GameState] = [self]
        var closed = Set<GameState>()
        
        let checkBetterScore = { (state: GameState) in
            let stateScore = state.countMisplacedCards()

            if stateScore < bestScore {
                bestScore = stateScore
                bestState = state
                onBetterStateFound?(bestState, closed.count)
            }
        }

        while !queue.isEmpty {
            if Task.isCancelled { return bestState }

            let state = queue.removeFirst()
            if state.isSolved {
                onBetterStateFound?(state, closed.count)
                return state
            }

            if closed.contains(state) {
                continue
            }
            closed.insert(state)
            onClosedAdded?(closed.count)
            checkBetterScore(state)

            if maxClosed != nil && closed.count >= maxClosed! {
                return bestState
            }
            
            if Task.isCancelled { return bestState }

            let stateMoves = state.getMoves()
            for move in stateMoves {
                if Task.isCancelled { return bestState }

                var newState = move.state

                if !closed.contains(newState) {
                    insert(&queue, &newState)
                    checkBetterScore(newState)
                }

                if Task.isCancelled { return bestState }
            }
        }

        return bestState
    }

    /**
     Depth first search
     - Parameters:
        - onClosedAdded: callback when a state is added to the closed list
        - onBetterStateFound: callback when a better state is found
        - maxClosed: maximum number of states in the closed list
     - Returns: the best state found
     */
    func depthFirstSearch(
        onClosedAdded: ((Int) -> Void)? = nil,
        onBetterStateFound: ((GameState, Int) -> Void)? = nil,
        maxClosed: Int? = nil
    ) async -> GameState? {
        return await self.generalizedSearch(insert: { queue, state in
            queue.insert(state, at: 0)
        }, onClosedAdded: onClosedAdded, onBetterStateFound: onBetterStateFound, maxClosed: maxClosed)
    }

    /**
     Breadth first search
     - Parameters:
        - onClosedAdded: callback when a state is added to the closed list
        - onBetterStateFound: callback when a better state is found
        - maxClosed: maximum number of states in the closed list
     - Returns: the best state found
     */
    func breadthFirstSearch(
        onClosedAdded: ((Int) -> Void)? = nil,
        onBetterStateFound: ((GameState, Int) -> Void)? = nil,
        maxClosed: Int? = nil
    ) async -> GameState? {
        return await self.generalizedSearch(insert: { queue, state in
            queue.append(state)
        }, onClosedAdded: onClosedAdded, onBetterStateFound: onBetterStateFound, maxClosed: maxClosed)
    }

    /**
     A* search
     - Parameters:
        - heuristic: the heuristic function
        - onClosedAdded: callback when a state is added to the closed list
        - onBetterStateFound: callback when a better state is found
        - maxClosed: maximum number of states in the closed list
     - Returns: the best state found
     */
    func aStar(
            heuristic: (GameState) async -> Int,
            onClosedAdded: ((Int) -> Void)? = nil,
            onBetterStateFound: ((GameState, Int) -> Void)? = nil,
            maxClosed: Int? = nil
    ) async -> GameState? {
        var open = Set<GameState>()
        var closed = Set<GameState>()

        let start = self
        let heuristicValue = await heuristic(start)
        start._gScore = 0
        start._fScore = start._gScore + heuristicValue
        start._hScore = heuristicValue
        open.insert(start)

        var bestState: GameState = start
        var bestScore: Int = start.countMisplacedCards()
        
        let checkBetterScore = { (state: GameState) in
            let stateScore = state.countMisplacedCards()

            if stateScore < bestScore {
                bestScore = stateScore
                bestState = state
                onBetterStateFound?(bestState, closed.count)
            }
        }

        while !open.isEmpty {
            if Task.isCancelled { return bestState }

            let state = open.min(by: { $0._fScore < $1._fScore })!

            if state.isSolved {
                onBetterStateFound?(state, closed.count)
                return state
            }

            open.remove(state)
            closed.insert(state)
            onClosedAdded?(closed.count)

            if maxClosed != nil && closed.count >= maxClosed! {
                return bestState
            }

            if Task.isCancelled { return bestState }

            let moves = state.getMoves()
            for move in moves {
                if Task.isCancelled { return bestState }

                let newState = move.state

                if closed.contains(newState) {
                    continue
                }

                let tentativeGScore = state._gScore + 1

                if !open.contains(newState) {
                    open.insert(newState)
                } else if tentativeGScore >= newState._gScore {
                    continue
                }

                let newHeuristicValue = await heuristic(newState)
                newState.parent = state
                newState._gScore = tentativeGScore
                newState._fScore = newState._gScore + newHeuristicValue
                newState._hScore = newHeuristicValue
                checkBetterScore(newState)

                if Task.isCancelled { return bestState }
            }
        }

        return nil
    }

    /**
     The hash value of the state (seed)
     */
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.seed)
    }

    /**
     The equality of two states
     */
    static func ==(lhs: GameState, rhs: GameState) -> Bool {
        return lhs.isEquals(to: rhs)
    }
}
