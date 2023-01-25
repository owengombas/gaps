import SwiftUI
import PlaygroundSupport

func executeAlgorithms(
    gameState: GameState,
    algorithms: [(String, (GameState) async -> GameState?)]
) async -> [(String, GameState?, TimeInterval)] {
    let res = await withTaskGroup(of: (String, GameState?, TimeInterval).self) { group in
        var values: [(String, GameState?, TimeInterval)] = []
        
        for algorithm in algorithms {
            group.addTask {
                let t = Timing().start()
                let s = await algorithm.1(gameState)
                return (algorithm.0, s, t.stop().elapsedTime)
            }
        }
        
        for await value in group {
            values.append(value)
        }
        
        return values
    }
    
    return res
}

func generateGames(n: Int, rows: Int, columns: Int) -> [GameState] {
    return (0..<n).map { _ in
        let g = GameState(columns: columns, rows: rows)
        g.removeLastCards()
        g.shuffle()
        return g
    }
}

func getPeformances(
    games: [GameState],
    algorithms: [(String, (GameState) async -> GameState?)]
) async -> [(String, TimeInterval)] {
    let res = await withTaskGroup(of: (String, TimeInterval).self) { group in
        var values: [(String, TimeInterval)] = []
        
        for algorithm in algorithms {
            group.addTask {
                let mean: TimeInterval = await withTaskGroup(of: TimeInterval.self) { group2 in
                    for game in games {
                        group2.addTask {
                            let t = Timing().start()
                            let s = await algorithm.1(game)
                            return t.stop().elapsedTime
                        }
                    }
                    
                    var sum = await group2.reduce(0.0, +)
                    
                    return sum / Double(games.count)
                }
                
                return (algorithm.0, mean)
            }
        }
        
        for await value in group {
            values.append(value)
        }
        
        return values
    }
    
    return res
}

func getArrangements(n: Int, range: ClosedRange<Int>) -> [[Double]] {
    var arrangements: [[Double]] = []
    
    if n == 1 {
        for i in range {
            arrangements.append([Double(i)])
        }
    } else {
        for i in range {
            for subArrangement in getArrangements(n: n-1, range: range) {
                if !subArrangement.contains(Double(i)) {
                    arrangements.append([Double(i)] + subArrangement)
                }
            }
        }
    }
    
    return arrangements
}


func findBestWeights(
    games: [GameState],
    range: ClosedRange<Int>,
    heuristics: [(GameState) async -> Int],
    maxClosed: Int? = nil
) async -> [(Double, Double, [Double])] {
    let arrangements = getArrangements(n: heuristics.count, range: range)
    var values: [(Double, Double, [Double])] = []
    
    print("Total iterations:", arrangements.count * games.count)
    
    for a in arrangements {
        let h = Heuristic.compose(heuristics: heuristics, weights: a)
        
        let res = await withTaskGroup(of: (Double?, Double?).self) { group in
            for game in games {
                group.addTask {
                    let t = Timing().start()
                    let gRes = await game.aStar(heuristic: h, maxClosed: maxClosed)
                    
                    return (gRes != nil ? Double(gRes!.countMisplacedCards()) : nil, t.stop().elapsedTime)
                }
            }
            
            let solved = group.filter{ $0.0 != nil }
            let solvedCount = Double(Array(arrayLiteral: solved).count)
            
            let timeMean = await solved.map{ $0.1! }.reduce(0.0, +) / solvedCount
            let placeMean = await solved.map{ $0.0! }.reduce(0.0, +) / solvedCount
            
            return (placeMean, timeMean)
        }
        
        values.append((res.0, res.1, a))
    }
    
    return values.sorted{ $0.0 < $1.0 }.sorted{ $0.1 < $1.0 }
}

let heuristics = [
    Heuristic.countMisplacedCards,
    Heuristic.stuckGaps(),
    Heuristic.wrongColumnPlacement
]

let bestWeights = await findBestWeights(
    games: generateGames(n: 10, rows: 4, columns: 7),
    range: 0...2,
    heuristics: heuristics,
    maxClosed: 5000
)

let h = Heuristic.compose(heuristics: heuristics, weights: [1, 1, 1])

let algorithms = [
    // ("bfs", { (g: GameState) in await g.breadthFirstSearch() }),
    ("DFS", { (g: GameState) in await g.depthFirstSearch() }),
    ("A*", { (g: GameState) in await g.aStar(heuristic: h) }),
]

let res = await getPeformances(games: generateGames(n: 20, rows: 4, columns: 7), algorithms: algorithms)

res.map { p in
    print(
        "name: \(p.0)",
        "Average time: \(p.1) seconds",
        separator: "\n"
    )
    print()
}
