//
//  Heuristic.swift
//  gaps
//
//  Created by owen on 23.01.23.
//

import Foundation

/**
 Heuristic class used to compute the score of a game state
*/
class Heuristic {
    /**
     Count the number of misplaced cards
     - Parameter state: the game state
     - Returns: the number of misplaced cards
     */
    static func countMisplacedCards(state: GameState) async -> Int {
        return state.countMisplacedCards()
    }

    /**
     Heuristic that penalizes gaps that are stuck by a card of a higher rank
     - Parameters:
       - stuckByMaxRankWeight: weight of the penalty for a gap stuck by a card of the maximum rank
       - stuckByGapWeight: weight of the penalty for a gap stuck by a gap
     - Returns: a heuristic function
     */
    static func stuckGaps(stuckByMaxRankWeight: Double = 1, stuckByGapWeight: Double = 1) -> (GameState) async -> Int {
        return { (state: GameState) in
            let maxRank = CardRank(rawValue: state.maxRank.rawValue - 1)
            var stuckGaps: Set<Int> = []
            var stuckByMaxRank: Int = 0
            var stuckByGap: Int = 0

            state.forEach { i, j, card, c, matrix in
                if i <= 0 {
                    return
                }

                let prevCard = state.previous(position: (i, j))
                let isGap = state.isGap(position: (i, j))

                if !isGap {
                    return
                }

                if prevCard == nil {
                    stuckGaps.insert(c)
                    stuckByGap += 1
                    return
                }

                if prevCard?.rank == maxRank && i < state.columns - 1 {
                    stuckGaps.insert(c)
                    stuckByMaxRank += 1
                    return
                }
            }

            return Int(stuckByMaxRankWeight * Double(stuckByMaxRank) + stuckByGapWeight * Double(stuckByGap))
        }
    }

    /**
     Heuristic that penalizes the cards that aren't in the right column
     - Parameter state: the game state
     - Returns: the number of misplaced cards on the columns
     */
    static func wrongColumnPlacement(state: GameState) async -> Int {
        var wrongColumnPlacement = 0
        
        state.forEach({ i, j, card, c, matrix in
            if card == nil {
                if i != state.columns - 1 {
                    wrongColumnPlacement += 1
                }
                return
            }

            if card!.rank.rawValue != i {
                wrongColumnPlacement += 1
            }
        })

        return wrongColumnPlacement
    }

    /**
     Compose a list of heuristics with weights into a single heuristic
     - Parameter weightsWithHeuristics: a list of weights and heuristics
     - Returns: a heuristic function
     */
    static func compose(_ weightsWithHeuristics: [(Double, (GameState) async -> Int)]) -> (GameState) async -> Int {
        return { state in
            return await withTaskGroup(of: Double.self) { group in
                for (weight, heuristic) in weightsWithHeuristics {
                    group.addTask {
                        let h = await heuristic(state)
                        return weight * Double(h)
                    }
                }
                
                return Int(await group.reduce(0.0, +))
            }
        }
    }

    /**
     Compose a list of heuristics with weights into a single heuristic
     - Parameters:
       - heuristics: a list of heuristics
       - weights: a list of weights
     - Returns: a heuristic function
     */
    static func compose(heuristics: [(GameState) async -> Int], weights: [Double]) -> (GameState) async -> Int {
        precondition(heuristics.count == weights.count)

        let values = Array(zip(weights, heuristics))

        return compose(values)
    }
}
