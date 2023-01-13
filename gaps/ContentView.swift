//
//  ContentView.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var _state: GameState = GameState(columns: 4, rows: 1)
    @StateObject private var _bestState: GameState = GameState()
    @StateObject private var _tempBestState: GameState = GameState()

    @State private var _peformMovesSafely: Bool = false
    @State private var _gaps: Int = 4
    @State private var _selected: Card? = nil
    @State private var _performingAlgorithm: Bool = false
    @State private var _maxClosed: Int = 100000
    @State private var _logs: String = ""
    @State private var _algorithmTask: Task<Void, Error>? = nil
    @State private var _timer: Timer? = nil
    @State private var _time: Double = 0
    @State var _seed: String = ""
    
    func generateNewGame() {
        self._selected = nil
        self._state.refresh()
        self._state.shuffle()
        self.removeLasts()
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
    
    func removeLasts() {
        self._selected = nil
        self._state.remove(CardRank(rawValue: self._state.columns - 1)!)
        self._state.computeMoves()
        self._bestState.copy(from: self._state)
    }
    
    func copyBestStateToMainGame() {
        self._selected = nil
        self._state.copy(from: self._bestState)
        self._state.computeMoves()
    }
    
    func wait(seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
    }
    
    func showBestStateAnimation(bestStatePath: [GameState], seconds: Double) async {
        for state in bestStatePath {
            self._bestState.copy(from: state)
            await wait(seconds: seconds)
        }
        self._state.computeMoves()
    }
    
    func perform(name: String = "", algorithm: @escaping () async -> GameState?, scroll: ScrollViewProxy) {
        withAnimation {
            scroll.scrollTo("algorithm", anchor: .top)
        }
        
        self.writeLog()
        self._performingAlgorithm = true
        self._bestState.copy(from: self._state)
        
        self.writeLog(logs: "Performing algorithm \(name) (with max closed nodes: \(self._maxClosed))", lineReturn: false)
        
        self._time = 0
        self._timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in self._time += 0.1 }
        
        self._algorithmTask = Task {
            let result = await algorithm()
            self._timer?.invalidate()
            
            if result === nil {
                self._performingAlgorithm = false
                self.writeLog(logs: "No solution found \(String(format: "%.2f", self._time)) seconds", lineReturn: true)
                return
            }
            
            let bestStatePath = result!.rewind()
            
            if bestStatePath.count < 1 {
                self.writeLog(logs: "No best states found in \(String(format: "%.2f", self._time)) seconds", lineReturn: true)
                self._performingAlgorithm = false
                return
            }
            
            self.writeLog(logs: "Algorithm performed in \(String(format: "%.2f", self._time)) seconds and found a path of \(bestStatePath.count) states, rewinding...", lineReturn: true)

            await wait(seconds: 1)
            
            await self.showBestStateAnimation(bestStatePath: bestStatePath, seconds: 0.25)
            
            self.writeLog(logs: "Rewinding performed, here is the best state found...", lineReturn: true)
            
            self._performingAlgorithm = false
        }
    }
    
    func interruptCurrentTask() {
        self._algorithmTask?.cancel()
        self._performingAlgorithm = false
        self.writeLog(logs: "Task canceled after \(String(format: "%.2f", self._time)) seconds")
        
        if !self._tempBestState.isEquals(to: self._bestState) {
            self.writeLog(logs: "Showing the best state found during the execution...", lineReturn: true)
        } else {
            self.writeLog(logs: "No better state found during the execution", lineReturn: true)
        }
        
        self._bestState.copy(from: self._tempBestState)
        self._timer?.invalidate()
    }
    
    func changeRows(_ nb: Int) {
        if !(1...4).contains(self._state.rows + nb) {
            return
        }
        
        
        self._state.rows += nb
        self._gaps = self._state.rows
        self.reset()
        self._bestState.copy(from: self._state)
    }
    
    func changeColumns(_ nb: Int) {
        if !(1...13).contains(self._state.columns + nb) {
            return
        }
        
        self._state.columns += nb
        self.reset()
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
    
    func onbetterStateFound(betterState: GameState, count: Int) -> Void {
        let t = self._time
        let percentage = Double(count) / Double(self._maxClosed) * 100
        self.writeLog(logs: "\(String(format: "%.3f", percentage))%) Found a better state in \(String(format: "%.2f", t)) seconds with score \(betterState.score) (\(count) node closed)", lineReturn: true)
        self._tempBestState.copy(from: betterState)
    }
    
    func onClosedAdded(count: Int) -> Void {
        let percentage = Double(count) / Double(self._maxClosed) * 100
        if percentage.truncatingRemainder(dividingBy: 2) != 0 { return }
        self.writeLog(logs: "\(String(format: "%.0f", percentage))% completed (\(count) max closed nodes out of \(self._maxClosed) processed)", lineReturn: true)
    }
    
    func onLoadSeed() {
        self._state.loadSeed(seed: self._seed)
        self._bestState.copy(from: self._state)
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
                        
                        HStack {
                            TextEditor(text: self.$_seed).frame(width: 500)
                            Button("Load seed", action: self.onLoadSeed)
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
                            }.disabled(self._performingAlgorithm)
                            
                            HStack {
                                Button("Generate new game", action: self.generateNewGame)
                                Button("Remove lasts", action: self.removeLasts)
                                Button("Shuffle", action: self.shuffle)
                                Button("Reset", action: self.reset)
                                Toggle("Apply move verification", isOn: self.$_peformMovesSafely)
                            }.disabled(self._performingAlgorithm)
                            
                            Spacer(minLength: 10)
                            
                            VStack {
                                HStack {
                                    Button("Perform dfs") {
                                        self.perform(name: "dfs", algorithm: self._bestState.depthFirstSearch, scroll: scroll)
                                    }
                                    
                                    Button("Perform bfs") {
                                        self.perform(name: "bfs", algorithm: self._bestState.breadthFirstSearch, scroll: scroll)
                                    }
                                }
                                
                                HStack {
//                                    TextField("Max closed", text: Binding(
//                                        get: { String(self._maxClosed) },
//                                        set: { self._maxClosed = Int($0) ?? 10000 }
//                                    )).frame(width: 200)
                                    
                                    Button("Perform A*") {
                                        self.perform(name: "A*", algorithm: self._bestState.aStarSearch, scroll: scroll)
                                    }
                                }.disabled(self._performingAlgorithm)
                            }
                            
                            if self._performingAlgorithm == false {
                                Spacer(minLength: 10)
                                
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
                        HStack {
                            Text("Algorithm tracing").font(.system(size: 20)).bold().id("algorithm")
                            Text(String(format: "%.2f", self._time)).font(.system(size: 20).monospaced()).bold()
                            Text("seconds").font(.system(size: 20)).bold()
                        }
                        
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
        }.onAppear {
            self._bestState.copy(from: self._state)
            self._state.loadSeed(seed: "0104XX000102")
            self._state.computeMoves()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.fixed(width: 1000, height: 1000))
    }
}
