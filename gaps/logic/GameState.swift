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
    
    var cards: [Card?] {
        get {
            return self.values.flatMap { card in
                return card
            }
        }
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
                    return Card.fromNumber(number: c, columns: m.columns, rows: m.rows)
                }
        )
    }
    
    init(seed: String) {
        super.init(columns: 0, rows: 0, defaultValue: { _, _, _, _ in return nil })
        let _ = self.loadSeed(seed: seed)
    }

    /**
     Get a copy of the actual state
     */
    override func copy() -> GameState {
        let s = GameState(columns: self.columns, rows: self.rows)

        s.setElements(value: { (i, j, _, _) in
            return self.getElement(column: i, row: j)
        })

        return s
    }

    /**
     Copy and apply the GameState passed in the from parameter to the current one
     */
    func copy(from: GameState) {
        super.copy(from: from)

        self._removedCards = from.removedCards
        self._parent = from.parent
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
     The gapses positions
     */
    func getGaps() -> [(Int, Int)] {
        return self.findPositions(condition: { i, j, v, c in
            return v == nil
        })
    }

    func isGap(column: Int, row: Int) -> Bool {
        return self.getElement(column: column, row: row) == nil
    }

    func isGap(position: (Int, Int)) -> Bool {
        return self.isGap(column: position.0, row: position.1)
    }

    /**
     Find a card position in the game
     */
    func find(card: Card?) -> (Int, Int)? {
        return self.findOnePosition(condition: { (i: Int, j: Int, v: Card?, c: Int) in
            return v?.toNumber(columns: self.columns) == card?.toNumber(columns: self.columns)
        })
    }

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
                    tempState.setElement(i: column, j: row, value: nil)
                } else {
                    let intValue = Int(value)
                    if intValue != nil {
                        tempState.setElement(i: column, j: row, value: Card.fromNumber(number: intValue!, columns: self.columns, rows: self.rows))
                    } else {
                        return false
                    }
                }
            }
        }
        
        self.copy(from: tempState)
        
        return true
    }

    /**
     Remove the king cards from the game
     */
    func remove(_ cardRank: CardRank) {
        self.forEach { i, j, v, c, m in
            if v?.rank == cardRank {
                self.setElement(i: i, j: j, value: nil)
                self._removedCards.append(v!)
            }
        }
    }
    
    func removeLastCards() {
        self.remove(CardRank(rawValue: self.columns - 1)!)
    }

    /**
     Generate all moves for a specific card rank to a specific position
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
    
    func getMoves() -> [Move] {
        let moves = self.getGaps().reduce(into: []) { (moves: inout [Move], gap: (Int, Int)) in
            // If the gap is at the begining of a row, then all aces can fill it
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
     */
    func possibleMoves(card: Card) -> [Move] {
        return self.getMoves().filter({ move in
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
     Get all the possible gaps where a card can be moved in (you have to perform computeMoves before)
     */
    func possibleGaps(card: Card) -> [Move] {
        return self.getMoves().filter({ move in
            return self.getElement(position: move.to)!.isEquals(to: card)
        })
    }

    /**
     Can the card be moved inside a specified gap (you have to perform computeMoves before)
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
     */
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
    func countMisplacedCards() -> Int {
        var count = 0

        for row in 0..<self.rows {
            let firstCard: Card? = self.getElement(column: 0, row: row)
            if firstCard === nil {
                continue
            }

            if firstCard!.rank != .ACE {
                continue
            }
            count += 1

            for column in 1..<self.columns {
                let card: Card? = self.getElement(column: column, row: row)

                if card === nil {
                    if column >= self.columns - 1 {
                        count += 1
                    }

                    break
                }

                if card!.suit != firstCard!.suit {
                    break
                }

                if card!.rank.rawValue != column {
                    break
                }

                count += 1
            }
        }

        return self.capacity - count
    }

    /**
     Is the GameState equals to an another one
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

        while !queue.isEmpty {
            if Task.isCancelled { return bestState }

            let checkBetterScore = { (state: GameState) in
                let stateScore = state.countMisplacedCards()

                if stateScore < bestScore {
                    bestScore = stateScore
                    bestState = state
                    onBetterStateFound?(bestState, closed.count)
                }
            }

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
     */
    func depthFirstSearch(
        onClosedAdded: ((Int) -> Void)? = nil,
        onBetterStateFound: ((GameState, Int) -> Void)? = nil
    ) async -> GameState? {
        return await self.generalizedSearch(insert: { queue, state in
            queue.insert(state, at: 0)
        }, onClosedAdded: onClosedAdded, onBetterStateFound: onBetterStateFound)
    }

    /**
     Breadth first search
     */
    func breadthFirstSearch(
        onClosedAdded: ((Int) -> Void)? = nil,
        onBetterStateFound: ((GameState, Int) -> Void)? = nil
    ) async -> GameState? {
        return await self.generalizedSearch(insert: { queue, state in
            queue.append(state)
        }, onClosedAdded: onClosedAdded, onBetterStateFound: onBetterStateFound)
    }

    func aStar(
            heuristic: (GameState) async -> Int,
            maxClosed: Int? = nil,
            onClosedAdded: ((Int) -> Void)? = nil,
            onBetterStateFound: ((GameState, Int) -> Void)? = nil
    ) async -> GameState? {
        var open = Set<GameState>()
        var closed = Set<GameState>()

        let start = self
        let heuristicValue = await heuristic(start)
        start._gScore = 0
        start._fScore = start._gScore + heuristicValue
        open.insert(start)

        var bestState: GameState = start
        var bestH: Int = heuristicValue

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

                if newHeuristicValue < bestH {
                    bestH = newHeuristicValue
                    bestState = newState
                    onBetterStateFound?(bestState, closed.count)
                }

                if Task.isCancelled { return bestState }
            }
        }

        return nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.seed)
    }
    
    static func ==(lhs: GameState, rhs: GameState) -> Bool {
        return lhs.isEquals(to: rhs)
    }
}
