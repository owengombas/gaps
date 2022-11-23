//
//  ContentView.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import SwiftUI

struct ContentView: View {
    private var _state: GameState = GameState()
    @State private var _bestState: GameState = GameState()
    @State private var _peformMovesSafely: Bool = false
    @State private var _gaps: Int = 4
    @State private var _selected: Card? = nil
    @State private var _performingAlgorithm: Bool = false
    @State private var _maxClosed: Int = 1000
    
    func generateNewGame() {
        self._selected = nil
        self._state.reset()
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
    
    func performAstar() {
        self._performingAlgorithm = true
        
        Task {
            var result: GameState? = self._bestState
            
            self._bestState.copy(from: self._state)
            
            print("Performing algorithm")
            
            while result !== nil || !self._bestState.isSolved {
                result = await self._bestState.astar(maxClosed: 100)
                
                if result === nil {
                    break
                }
                
                self._bestState.copy(from: result!)
                print("Better state found")
            }
            
            print("Best state found")
            
            self._performingAlgorithm = false
        }
    }
    
    func performBranchAndBound() {
        self._performingAlgorithm = true
        
        Task {
            var result: GameState? = self._bestState
            
            self._bestState.copy(from: self._state)
            
            print("Performing algorithm")
            
            while result !== nil || !self._bestState.isSolved {
                result = await self._bestState.branchAndBound(maxClosed: 100)
                
                if result === nil {
                    break
                }
                
                self._bestState.copy(from: result!)
                print("Better state found")
            }
            
            print("Best state found")
            
            self._performingAlgorithm = false
        }
    }
    
    func perform(algorithm: @escaping () async -> GameState?) {
        self._performingAlgorithm = true
        
        Task {
            var result: GameState? = self._bestState
            
            self._bestState.copy(from: self._state)
            
            print("Performing algorithm")
            
            while result !== nil {
                result = await algorithm()
                
                if result === nil {
                    break
                }
                
                self._bestState.copy(from: result!)
            }
            
            print("Best state finish", self._bestState)
            self._performingAlgorithm = false
        }
    }
    
    func changeRows(_ nb: Int) {
        if !(1...4).contains(self._state.rows + nb) {
            return
        }
        
        self.reset()
        self._state.rows += nb
        self._bestState.copy(from: self._state)
    }
    
    func changeColumns(_ nb: Int) {
        if !(1...13).contains(self._state.columns + nb) {
            return
        }
        
        self.reset()
        self._state.columns += nb
        self._bestState.copy(from: self._state)
    }
    
    func changeGaps(_ nb: Int) {
        if !(0..<self._state.capacity).contains(self._gaps + nb) {
            return
        }
        
        self.reset()
        self._gaps += nb
        self._bestState.copy(from: self._state)
    }
    
    func onCardChange(card: Card, to: (Int, Int)) {
        self._bestState.copy(from: self._state)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    Text("Main game").font(.system(size: 20)).bold()
                    
                    StateUI(
                        state: self._state,
                        selected: self.$_selected,
                        peformMovesSafely: self.$_peformMovesSafely,
                        onCardChange: onCardChange
                    )
                }
                
                VStack(spacing: 25) {
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
                            set: { self._maxClosed = Int($0) ?? 1000 }
                        )).frame(width: 50)
                        
                        Button("Perform A*", action: self.performAstar)
                        Button("Perform Branch and bound", action: self.performBranchAndBound)
                    }.disabled(self._performingAlgorithm)
                    
                    if self._performingAlgorithm {
                        HStack {
                            ProgressView()
                        }
                    }
                    
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
                
                Spacer(minLength: 100)
                
                VStack {
                    Text("Algorithm tracing").font(.system(size: 20)).bold()
                    
                    StateUI(
                        state: self._bestState,
                        selected: Binding.constant(nil),
                        peformMovesSafely: Binding.constant(false),
                        onCardChange: nil
                    ).opacity(0.7)
                }
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
