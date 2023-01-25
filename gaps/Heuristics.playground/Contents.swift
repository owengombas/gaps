import SwiftUI
import PlaygroundSupport

let heuristics = [
    Heuristic.countMisplacedCards,
    Heuristic.stuckGaps(),
    Heuristic.wrongColumnPlacement
]

let bestWeights = await Statistics.findBestWeights(
    games: Statistics.generateGames(n: 5, rows: 4, columns: 13),
    range: 0...5,
    heuristics: heuristics,
    maxClosed: 3000
)

let h = Heuristic.compose(heuristics: heuristics, weights: [1, 1, 1])

let algorithms = [
    // ("bfs", { (g: GameState) in await g.breadthFirstSearch() }),
    ("DFS", { (g: GameState) in await g.depthFirstSearch() }),
    ("A*", { (g: GameState) in await g.aStar(heuristic: h) }),
]

let res = await Statistics.getPeformances(games: Statistics.generateGames(n: 20, rows: 4, columns: 7), algorithms: algorithms)

res.map { p in
    print(
        "name: \(p.0)",
        "Average time: \(p.1) seconds",
        separator: "\n"
    )
    print()
}
