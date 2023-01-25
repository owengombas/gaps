//
//  Statistics.swift
//  gaps
//
//  Created by owen on 25.01.23.
//

import Foundation

class Statistics {
    static func generateGames(n: Int, rows: Int, columns: Int) -> [GameState] {
        return (0..<n).map { _ in
            let g = GameState(columns: columns, rows: rows)
            g.removeLastCards()
            g.shuffle()
            return g
        }
    }
    
    static func getArrangements(n: Int, range: ClosedRange<Int>) -> [[Double]] {
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
    
    static func findBestWeights(
        games: [GameState],
        range: ClosedRange<Int>,
        heuristics: [(GameState) async -> Int],
        maxClosed: Int? = nil
    ) async -> [(Double, Double, [Double])] {
        let arrangements = getArrangements(n: heuristics.count, range: range).shuffled()
        var values: [(Double, Double, [Double])] = []
        
        print("Total iterations:", arrangements.count * games.count)
        
        for a in arrangements {
            let h = Heuristic.compose(heuristics: heuristics, weights: a)
            
            let res = await withTaskGroup(of: (Double?, Double?).self) { group in
                for game in games {
                    group.addTask {
                        let t = Timing().start()
                        let gRes = await game.aStar(heuristic: h, maxClosed: maxClosed)
                        
                        if gRes == nil {
                            return (nil, t.stop().elapsedTime)
                        }
                        
                        return (Double(gRes!.countMisplacedCards()), t.stop().elapsedTime)
                    }
                }
                
                var count = 0.0
                var totalMisplacedCards = 0.0
                var totalTime = 0.0
                for await value in group {
                    if value.0 == nil {
                        continue
                    }
                    
                    totalMisplacedCards += value.0!
                    totalTime += value.1!
                    count += 1
                }
                
                if count == 0 {
                    return (0.0, 0.0)
                }
                
                let timeMean = totalTime / count
                let placeMean = totalMisplacedCards / count
                
                return (placeMean, timeMean)
            }
            
            print(res.0, res.1, a)
            values.append((res.0, res.1, a))
        }
        
        values.sort{ $0.1 < $1.1 }
        values.sort{ $0.0 < $1.0 }
        
        return values
    }
    
    static func getPeformances(
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
                                _ = await algorithm.1(game)
                                return t.stop().elapsedTime
                            }
                        }
                        
                        var sum = 0.0
                        var count = 0.0
                        for await value in group2 {
                            count += 1
                            sum += value
                        }
                        
                        return sum / count
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
}
