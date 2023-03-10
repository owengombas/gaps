import SwiftUI
import PlaygroundSupport

// let g = GameState(seed: "04100015333811323605072804XX24031620XX3437XX1731271801263530XX1014120802232106132522")

let heuristics = [
    Heuristic.countMisplacedCards,
    Heuristic.stuckGaps(),
    Heuristic.wrongColumnPlacement
]
// let weights: [Double] = [5, 1, 4]
// let h = Heuristic.compose(heuristics: heuristics, weights: weights)

// let algorithms = [
//     ("DFS", { (g: GameState) in await g.depthFirstSearch() }),
//     ("A*", { (g: GameState) in await g.aStar(heuristic: h) }),
// ]

// let res = await Statistics.executeAlgorithmsOnOneGame(gameState: g, algorithms: algorithms)

// await Statistics.executeAlgorithmsOnMultipleGames(games: Statistics.generateGames(n: 10, rows: 4, columns: 13), algorithms: algorithms)

let bestWeights = await Statistics.findBestWeights(
    games: Statistics.generateGames(n: 5, rows: 4, columns: 13),
    range: 0...5,
    heuristics: heuristics,
    maxClosed: 3000
)
