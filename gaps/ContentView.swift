//
//  ContentView.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var _state: GameState = GameState()
    @StateObject private var _bestState: GameState = GameState()
    @State private var _peformMovesSafely: Bool = false
    @State private var _gaps: Int = 4
    @State private var _selected: Card? = nil
    @State private var _performingAlgorithm: Bool = false
    @State private var _maxClosed: Int = 100
    @State private var _logs: String = ""
    @State private var _algorithmTask: Task<Void, Error>? = nil
    
    func generateNewGame() {
        self._selected = nil
        self._state.refresh()
        self._state.shuffle()
        self._state.remove(.KING)
        self._state.computeMoves()
        self._bestState.copy(from: self._state)
    }
    
    func reset() {
        self._selected = nil
        self._state.reset()
        self._state.computeMoves()
        self._bestState.copy(from: self._state)
    }
    
    func shuffle() {
        self._selected = nil
        self._state.shuffle()
        self._state.computeMoves()
        self._bestState.copy(from: self._state)
    }
    
    func removeRandomly() {
        self._selected = nil
        self._state.removeCardsRandomly(numberOfCards: self._gaps)
        self._state.computeMoves()
        self._bestState.copy(from: self._state)
    }
    
    func removeKings() {
        self._selected = nil
        self._state.remove(.KING)
        self._state.computeMoves()
        self._bestState.copy(from: self._state)
    }
    
    func copyBestStateToMainGame() {
        self._selected = nil
        self._state.copy(from: self._bestState)
        self._state.computeMoves()
    }
    
    func wait(seconds: Double) async {
        try! await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
    }
    
    func showBestStateAnimation(bestStatePath: [GameState], seconds: Double) async {
        for state in bestStatePath {
            self._bestState.copy(from: state)
            await wait(seconds: seconds)
        }
        self._state.computeMoves()
    }
    
    func perform(name: String = "", algorithm: @escaping () async -> GameState?) {
        self.writeLog()
        self._performingAlgorithm = true
        self._bestState.copy(from: self._state)
        
        self.writeLog(logs: "Performing algorithm \(name) (with max closed nodes: \(self._maxClosed))", lineReturn: false)
        
        self._algorithmTask = Task {
            let result = await algorithm()
            
            if result === nil {
                return
            }
            
            let bestStatePath = result!.rewind()
            
            if bestStatePath.count < 1 {
                self.writeLog(logs: "No best states found", lineReturn: true)
                self._performingAlgorithm = false
                return
            }
            
            self.writeLog(logs: "Algorithm performed found a path of \(bestStatePath.count) states, rewinding...", lineReturn: true)
            
            await wait(seconds: 1)
            
            await self.showBestStateAnimation(bestStatePath: bestStatePath, seconds: 0.5)
            
            self.writeLog(logs: "Rewinding performed, here is the best state found...", lineReturn: true)
            
            self._performingAlgorithm = false
        }
    }
    
    func interruptCurrentTask() {
        self._algorithmTask?.cancel()
        self._performingAlgorithm = false
        self.writeLog(logs: "Task canceled")
    }
    
    func changeRows(_ nb: Int) {
        if !(1...4).contains(self._state.rows + nb) {
            return
        }
        
        self._state.rows += nb
        self._bestState.copy(from: self._state)
    }
    
    func changeColumns(_ nb: Int) {
        if !(1...13).contains(self._state.columns + nb) {
            return
        }
        
        self._state.columns += nb
        self._bestState.copy(from: self._state)
    }
    
    func changeGaps(_ nb: Int) {
        if !(0..<self._state.capacity).contains(self._gaps + nb) {
            return
        }
        
        self._gaps += nb
        self._bestState.copy(from: self._state)
    }
    
    func onCardChangeMain(card: Card, to: (Int, Int)) {
        self._bestState.copy(from: self._state)
    }
    
    func onCardChangeAlgorithm(card: Card, to: (Int, Int)) {
        self._state.copy(from: self._bestState)
    }
    
    func writeLog(logs: Any..., lineReturn: Bool = true) {
        if logs.isEmpty {
            self._logs = ""
            return
        }
        
        print(logs)
        
        if lineReturn {
            self._logs += "\n"
        }
        
        for log in logs {
            self._logs += String(describing: log)
            self._logs += " "
        }
    }
    
    var body: some View {
        ScrollView {
            ScrollViewReader { scroll in
                VStack(spacing: 100) {
                    VStack(spacing: 20) {
                        VStack(spacing: 20) {
                            Text("Main game").font(.system(size: 20)).bold().id("title")
                            
                            StateUI(
                                state: self._state,
                                selected: self.$_selected,
                                peformMovesSafely: self.$_peformMovesSafely,
                                blockMove: self.$_performingAlgorithm,
                                onCardChange: onCardChangeMain
                            ).disabled(self._performingAlgorithm)
                        }
                        
                        VStack(spacing: 10) {
                            HStack {
                                Stepper("\(self._state.rows) rows", onIncrement: {
                                    self.changeRows(1)
                                }, onDecrement: {
                                    self.changeRows(-1)
                                })
                                
                                Stepper("\(self._state.columns) columns", onIncrement: {
                                    self.changeColumns(1)
                                }, onDecrement: {
                                    self.changeColumns(-1)
                                })
                                
                                Stepper("\(self._gaps) gaps", onIncrement: {
                                    self.changeGaps(1)
                                }, onDecrement: {
                                    self.changeGaps(-1)
                                })
                            }.disabled(self._performingAlgorithm)
                            
                            HStack {
                                Button("Generate new game", action: self.generateNewGame)
                                Button("Shuffle", action: self.shuffle)
                                Button("Reset", action: self.reset)
                                Button("Remove randomly", action: self.removeRandomly)
                                Button("Remove Kings", action: self.removeKings)
                                Toggle("Apply move verification", isOn: self.$_peformMovesSafely)
                            }.disabled(self._performingAlgorithm)
                            
                            HStack {
                                TextField("Max closed", text: Binding(
                                    get: { String(self._maxClosed) },
                                    set: { self._maxClosed = Int($0) ?? 100 }
                                )).frame(width: 50)
                                
                                Button("Perform Branch and bound") {
                                    self.perform(name: "branch and bound") {
                                        return await self._bestState.branchAndBound(maxClosed: self._maxClosed)
                                    }
                                    
                                    withAnimation {
                                        scroll.scrollTo("algorithm", anchor: .top)
                                    }
                                }
                                
                                Button("Perform A*") {
                                    self.perform(name: "A*") {
                                        return await self._bestState.astar(maxClosed: self._maxClosed)
                                    }
                                    
                                    withAnimation {
                                        scroll.scrollTo("algorithm", anchor: .top)
                                    }
                                }
                            }.disabled(self._performingAlgorithm)
                            
                            if self._performingAlgorithm == false {
                                VStack {
                                    Text("\(self._state.moves.count) Children states found").bold()
                                    
                                    VStack {
                                        ForEach(self._state.moves, id: \.state.description) { move in
                                            Button(move.description, action: {
                                                self._state.performMove(move: move)
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 20) {
                        Text("Algorithm tracing").font(.system(size: 20)).bold().id("algorithm")
                        
                        StateUI(
                            state: self._bestState,
                            selected: self.$_selected,
                            peformMovesSafely: self.$_peformMovesSafely,
                            blockMove: self.$_performingAlgorithm,
                            onCardChange: self.onCardChangeAlgorithm
                        )
                        
                        if self._performingAlgorithm {
                            HStack {
                                ProgressView()
                            }
                        }
                        
                        if self._performingAlgorithm {
                            Button("Stop execution", action: self.interruptCurrentTask).disabled(!self._performingAlgorithm)
                        } else {
                            Button("Apply to main game") {
                                withAnimation {
                                    scroll.scrollTo("title", anchor: .top)
                                }
                                
                                self.copyBestStateToMainGame()
                            }.disabled(self._performingAlgorithm)
                        }
                        
                        TextEditor(text: .constant(self._logs)).disabled(true)
                    }
                }.padding(20)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.fixed(width: 1000, height: 1000))
    }
}
