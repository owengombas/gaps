//
//  ContentView.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import SwiftUI
import Charts

struct ContentView: View {
    private let h = Heuristic.compose((1, Heuristic.countMisplacedCards))

    @StateObject private var _state: GameState = GameState(columns: 10, rows: 4)
    @State private var _stateCards: [[Card?]] = []
    @State private var _moves: [Move] = []
    
    @StateObject private var _bestState: GameState = GameState()
    @State private var _bestStateCards: [[Card?]] = []
    
    @StateObject private var _tempBestState: GameState = GameState()
    
    @State private var _stateScore: Int = 0
    @State private var _peformMovesSafely: Bool = false
    @State private var _gaps: Int = 4
    @State private var _selected: Card? = nil
    @State private var _performingAlgorithm: Bool = false
    @State private var _performingAnimation: Bool = false
    @State private var _maxClosed: Int = 100000
    @State private var _logs: String = ""
    @State private var _algorithmTask: Task<Void, Error>? = nil
    @State private var _timer: Timer? = nil
    @State private var _time: Double = 0
    @State private var _seed: String = ""
    @State private var _scroll: ScrollViewProxy? = nil
    @State private var _viewChildren: Bool = false
    @State private var _closedNodesOverTimePerAlgorithms: [Measure] = []
    @State private var _betterStateFoundOverTime: [Measure] = []
    
    func publishState() {
        self._stateCards = self._state.values
        self._moves = self._state.getMoves()
    }
    
    func publishBestState() {
        self._bestStateCards = self._bestState.values
    }
    
    func copyStateToBestState() {
        self._bestState.copy(from: self._state)
        self.publishBestState()
    }
    
    func publishEverything() {
        self.publishState()
        self.copyStateToBestState()
    }
    
    func onAppear() {
        self.publishEverything()
    }

    func generateNewGame() {
        self._selected = nil
        self._state.refresh()
        self._state.shuffle()
        self.removeLasts()
        self.publishEverything()
    }
    
    func reset() {
        self._selected = nil
        self._state.reset()
        self._bestState.copy(from: self._state)
        self.publishEverything()
    }
    
    func shuffle() {
        self._selected = nil
        self._state.shuffle()
        self._bestState.copy(from: self._state)
        self.publishEverything()
    }
    
    func removeLasts() {
        self._selected = nil
        self._state.remove(CardRank(rawValue: self._state.columns - 1)!)
        self._bestState.copy(from: self._state)
        self.publishEverything()
    }
    
    func copyBestStateToMainGame() {
        self._selected = nil
        self.publishEverything()
    }
    
    func wait(seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
    }
    
    func scroll(to: String, anchor: UnitPoint = .top) {
        withAnimation {
            self._scroll!.scrollTo(to, anchor: .top)
        }
    }
    
    func showBestStateAnimation(bestStatePath: [GameState], seconds: Double) async {
        self._performingAnimation = true

        await wait(seconds: 1)
        for state in bestStatePath {
            if !self._performingAnimation {
                cancelAnimation()
                return
            }

            self._bestState.copy(from: state)
            self.publishBestState()
            
            await wait(seconds: seconds)
        }

        self._performingAnimation = false
    }

    func cancelAnimation() {
        self._bestState.copy(from: self._tempBestState)
        self._performingAnimation = false
        
        self.publishBestState()
    }
    
    func perform(
        name: String = "",
        algorithm: @escaping (
            @escaping (Int) -> Void,
            @escaping (GameState) -> Void
        ) async -> GameState?,
        heuristicName: String? = nil
    ) {
        self.scroll(to: "algorithm")
        
        if self._logs.count > 0 {
            self.writeLog(logs: "\n")
        }
        
        self._performingAlgorithm = true
        self._bestState.copy(from: self._state)
        self.publishBestState()
        
        self.writeLog(logs: "Performing algorithm \(name)", lineReturn: false)

        self._time = 0.0
        let misplacedCards = self._state.countMisplacedCards()
        self._betterStateFoundOverTime.append(Measure(x: self._time, y: Double(misplacedCards), z: name))
        self._timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in Task { self._time += 0.1 } }

        self._betterStateFoundOverTime.removeAll(where: { $0.z == name })
        self._closedNodesOverTimePerAlgorithms.removeAll(where: { $0.z == name })

        let checkCancelledTask = {
            if self._algorithmTask!.isCancelled {
                self._performingAnimation = true
                self._performingAlgorithm = false
                return true
            }

            return false
        }
        
        var lastT = self._time
        var closedNodesCount = 0
        
        let onClosedAdded: (Int) -> Void = { closedCount in
            let nodeInterval = 1000
            if closedCount % nodeInterval == 0 {
                var dT = self._time - lastT
                if dT == 0 {
                    dT = 1
                }
                
                self.writeLog(logs: "Visited \(closedCount)")
                
                let nodesPerSeconds = Double(nodeInterval) / dT
                
                self.writeLog(logs: "(\(String(format: "%.2f", nodesPerSeconds)) nodes/s for the last \(nodeInterval) nodes)", lineReturn: false)
                
                self._closedNodesOverTimePerAlgorithms.append(Measure(x: Double(closedCount), y: dT, z: name))
                
                lastT = self._time
            }
            closedNodesCount = closedCount
        }
        
        let onBetterStateFound: (GameState) -> Void = { state in
            let misplacedCards = state.countMisplacedCards()
            self.writeLog(logs: "Better state found with \(misplacedCards) misplaced cards")
            self._betterStateFoundOverTime.append(Measure(x: self._time, y: Double(misplacedCards), z: name))
            self._tempBestState.copy(from: state)
        }

        self._algorithmTask = Task {
            if checkCancelledTask() { return }
            
            let result = await algorithm(onClosedAdded, onBetterStateFound)
            self._performingAnimation = true
            self._performingAlgorithm = false

            if checkCancelledTask() { return }
            
            let nodesPerSecondes = Int(Double(closedNodesCount) / (self._time == 0 ? 1 : self._time))
            
            self._timer?.invalidate()
            
            if result === nil {
                self._performingAlgorithm = false
                self.writeLog(logs: "No solution found \(String(format: "%.2f", self._time)) seconds (with performance: \(nodesPerSecondes) nodes/s)", lineReturn: true)
                return
            }
            
            if result!.countMisplacedCards() > 0 {
                self.writeLog(logs: "The game couldn't be fully solved, showing the best solution found...", lineReturn: true)
            }


            if checkCancelledTask() { return }

            let bestStatePath = result!.rewind()
            
            self.writeLog(logs: "Algorithm performed in \(String(format: "%.2f", self._time)) seconds (with performance: \(nodesPerSecondes) nodes/s) and found a path of \(bestStatePath.count) states, rewinding...", lineReturn: true)

            if checkCancelledTask() { return }

            await self.showBestStateAnimation(bestStatePath: bestStatePath, seconds: 0.25)

            if checkCancelledTask() { return }
            
            self.writeLog(logs: "Rewinding performed, here is the best state found...", lineReturn: true)
        }
    }
    
    func interruptCurrentTask() async {
        if !self._performingAlgorithm {
            return
        }
        
        self._algorithmTask?.cancel()
        self._performingAlgorithm = false

        self.writeLog(logs: "Task canceled after \(String(format: "%.2f", self._time)) seconds")
        
        if !self._tempBestState.isEquals(to: self._bestState) {
            self.writeLog(logs: "Showing the best state found during the execution...", lineReturn: true)
        } else {
            self.writeLog(logs: "No better state found during the execution", lineReturn: true)
        }
        
        self._timer?.invalidate()

        await self.showBestStateAnimation(bestStatePath: self._tempBestState.rewind(), seconds: 0.25)
    }
    
    func changeRows(_ nb: Int) {
        if !(1...4).contains(self._state.rows + nb) {
            return
        }
        
        self._state.rows += nb
        self._gaps = self._state.rows
        self.reset()
        self._bestState.copy(from: self._state)
        
        self.publishEverything()
    }
    
    func changeColumns(_ nb: Int) {
        if !(1...13).contains(self._state.columns + nb) {
            return
        }
        
        self._state.columns += nb
        self.reset()
        self._bestState.copy(from: self._state)
        
        self.publishEverything()
    }
    
    func changeGaps(_ nb: Int) {
        if !(0..<self._state.capacity).contains(self._gaps + nb) {
            return
        }
        
        self._gaps += nb
        self._bestState.copy(from: self._state)
        
        self.publishEverything()
    }
    
    func onCardChangeMain(card: Card, to: (Int, Int)) {
        self._bestState.copy(from: self._state)
        
        self.publishEverything()
    }
    
    func onCardChangeAlgorithm(card: Card, to: (Int, Int)) {
        self._state.copy(from: self._bestState)
        
        self.publishEverything()
    }
    
    func writeLog(logs: Any..., lineReturn: Bool = true) {
        if logs.isEmpty {
            self._logs = ""
            return
        }
        
        print(logs)
        
        if lineReturn {
            self._logs = "\n" + self._logs
        }
        
        var res = ""
        for log in logs {
            res = String(describing: log) + " "
        }
        
        self._logs = res + self._logs
    }
    
    func onbetterStateFound(betterState: GameState, count: Int) -> Void {
        let t = self._time
        let percentage = Double(count) / Double(self._maxClosed) * 100
        self.writeLog(logs: "\(String(format: "%.3f", percentage))%) Found a better state in \(String(format: "%.2f", t)) seconds with score \(String(describing: betterState.countMisplacedCards)) (\(count) node closed)", lineReturn: true)
        self._tempBestState.copy(from: betterState)
    }
    
    func onClosedAdded(count: Int) -> Void {
        let percentage = Double(count) / Double(self._maxClosed) * 100
        if percentage.truncatingRemainder(dividingBy: 2) != 0 { return }
        self.writeLog(logs: "\(String(format: "%.0f", percentage))% completed (\(count) max closed nodes out of \(self._maxClosed) processed)", lineReturn: true)
    }
    
    func onLoadSeed() {
        let isOkay = self._state.loadSeed(seed: self._seed)
        
        if isOkay {
            self._bestState.copy(from: self._state)
        } else {
            self.writeLog()
            self.writeLog(logs: "Wrong seed format", lineReturn: false)
            self.scroll(to: "algorithm")
        }
        
        self.publishEverything()
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
                                cards: self.$_stateCards,
                                selected: self.$_selected,
                                peformMovesSafely: self.$_peformMovesSafely,
                                blockMove: self.$_performingAlgorithm,
                                cardWidth: 80,
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
                                    Button("Perform DFS") {
                                        self.perform(name: "DFS", algorithm: self._bestState.depthFirstSearch)
                                    }
                                    
                                    Button("Perform BFS") {
                                        self.perform(name: "BFS", algorithm: self._bestState.breadthFirstSearch)
                                    }
                                    
                                    Button("Perform A*") {
                                        self.perform(
                                                name: "A*",
                                                algorithm: { (onClosedAdded: ((Int) -> Void)?, onBetterStateFound: ((GameState) -> Void)?) in
                                                    return await self._bestState.aStar(heuristic: self.h, onClosedAdded: onClosedAdded, onBetterStateFound: onBetterStateFound)
                                                }, heuristicName: "Misplaced cards"
                                        )
                                    }
                                }.disabled(self._performingAlgorithm)
                            }
                            
                            if self._performingAlgorithm == false {
                                Spacer(minLength: 10)
                                
                                VStack {
                                    Text("\(self._moves.count) Children states found").bold()
                                    
                                    if self._viewChildren {
                                        Button("Hide children states") {
                                            self._viewChildren = false
                                        }
                                        
                                        Spacer(minLength: 50)
                                        
                                        VStack(spacing: 50) {
                                            ForEach(self._moves, id: \.state.description) { move in
                                                VStack {
                                                    StateUI(
                                                        state: move.state,
                                                        cards: Binding.constant(move.state.values),
                                                        selected: Binding.constant(nil),
                                                        peformMovesSafely: Binding.constant(false),
                                                        blockMove: Binding.constant(true),
                                                        cardWidth: 30
                                                    ).frame(maxWidth: .infinity)
                                                    
                                                    Button("Peform this move - \(move.description)") {
                                                        let _ = self._state.performMove(move: move)
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        Button("Show children states") {
                                            self._viewChildren = true
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
                            cards: self.$_bestStateCards,
                            selected: self.$_selected,
                            peformMovesSafely: self.$_peformMovesSafely,
                            blockMove: self.$_performingAlgorithm,
                            cardWidth: 80,
                            onCardChange: self.onCardChangeAlgorithm
                        )

                        if self._performingAlgorithm {
                            HStack {
                                ProgressView()
                            }
                        }
                        
                        if self._performingAlgorithm {
                            Button("Stop execution") {
                                Task {
                                   await self.interruptCurrentTask()
                                }
                            }
                        }

                        if self._performingAnimation {
                            Button("Stop animation") {
                                self._performingAnimation = false
                            }
                        }

                        if !self._performingAlgorithm  && !self._performingAnimation {
                            Button("Apply to main game") {
                                self.scroll(to: "title")
                                self.copyBestStateToMainGame()
                            }
                        }
                        
                        Spacer(minLength: 50)
                        
                        VStack {
                            TextEditor(text: .constant(self._logs))
                                .frame(height: 300)
                                .font(.system(size: 11).monospaced())
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Button("Clear logs") {
                                self._logs = ""
                            }
                        }
                    }
                    
                    if #available(macOS 13.0, *) {
                        VStack(spacing: 100) {
                            ChartUI(
                                    values: self.$_betterStateFoundOverTime,
                                    title: Binding.constant("Better score on state found per algorithms"),
                                    xTitle: Binding.constant("Time (s)"),
                                    yTitle: Binding.constant("State score"),
                                    colorTitle: Binding.constant("Algorithm"),
                                    colorsTitles: Binding.constant([
                                        "A*": .green, "DFS": .pink, "BFS": .orange
                                    ]),
                                    showIfNotEmpty: Binding.constant(true)
                            )

                            ChartUI(
                                values: self.$_closedNodesOverTimePerAlgorithms,
                                title: Binding.constant("Closed nodes over time per algorithms"),
                                xTitle: Binding.constant("Closed nodes"),
                                yTitle: Binding.constant("Time (s)"),
                                colorTitle: Binding.constant("Algorithm"),
                                colorsTitles: Binding.constant([
                                    "A*": .green, "DFS": .pink, "BFS": .orange
                                ]),
                                showIfNotEmpty: Binding.constant(true)
                            )
                        }
                    }
                }.onAppear {
                    self._scroll = scroll
                }
            }
        }.onAppear(perform: self.onAppear)
        .frame(height: 800)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.fixed(width: 1000, height: 1000))
    }
}
