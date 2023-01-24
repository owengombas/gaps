//
//  Heuristic.swift
//  gaps
//
//  Created by owen on 23.01.23.
//

import Foundation

class Heuristic {
    static func countMisplacedCards(state: GameState) -> Int {
        return state.countMisplacedCards()
    }

    static func stuckGaps(state: GameState) -> Int {
        let maxRank = state.maxRank
        var stuckGaps = 0

        state.forEach { i, i2, card, i3, matrix in
            let prevCard = state.previous(position: (i, i2))
            if prevCard!.rank == maxRank || prevCard == nil {
                stuckGaps += 1
            }
        }

        return stuckGaps
    }

    static func columnPlacement(state: GameState) -> Int {
        let columnPlacement = 0

        return columnPlacement
    }

    static func compose(_ weightsWithHeuristics: (Int, (GameState) -> Int)...) -> (GameState) -> Int {
        return { state in
            var score = 0

            for (weight, heuristic) in weightsWithHeuristics {
                score += weight * heuristic(state)
            }

            return score
        }
    }
}
