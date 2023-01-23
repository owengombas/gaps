//
//  Heuristic.swift
//  gaps
//
//  Created by owen on 23.01.23.
//

import Foundation

class Heuristic {
    static let calculation = [
        (0, Heuristic.columnPlacement),
        (1, Heuristic.countMisplacedCards),
        (0, Heuristic.columnPlacement)
    ]

    // region Heuristic functions

    static func score(state: GameState) -> Int {
        var score = 0

        for (weight, heuristic) in Heuristic.calculation {
            score += weight * heuristic(state)
        }

        return score
    }

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
        var columnPlacement = 0

        return columnPlacement
    }

    // endregion
}
