//
//  ContentView.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var _state: GameState = GameState()
    @State private var _depth = 0
    @State private var _selected: Card? = nil
    @State private var _peformMovesSafely: Bool = false
    
    var items: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    func generateNewGame() {
        self._selected = nil
        self._depth = 0
        self._state.reset()
        self._state.shuffle()
        self._state.removeKings()
        self._state.computeMoves()
        print(self._state.moves.count)
    }
    
    func getPositionFromHGridIndex(index: Int) -> (Int, Int) {
        let line = index % self._state.lines
        let column = Int(floor(Double(index) / Double(self._state.lines)))
        return (column, line)
    }
    
    var body: some View {
        VStack {
            ScrollView {
                
                Text("Gaps").font(.system(size: 20)).bold()
                
                Spacer(minLength: 20)
                
                Text("Depth: \(_depth)")
                Group {
                    LazyHGrid(rows: items) {
                        ForEach(Array(self._state.toArray(fromTopToBottom: true).enumerated()), id: \.offset) {index, card in
                            Group {
                                if card != nil {
                                    Image("\(card!.cardColor)_\(card!.cardNumber)")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .onTapGesture {
                                            if self._selected === nil {
                                                self._selected = card
                                            } else if self._selected === card {
                                                self._selected = nil
                                            }
                                        }
                                        .padding(3)
                                        .cornerRadius(5)
                                        .if(self._selected === card, transform: { view in
                                            view.overlay(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(.blue, lineWidth: 3)
                                            )
                                        })
                                        .if(self._state.isMovable(card: card!) && self._selected === nil, transform: { view in
                                            view.overlay(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(.red, lineWidth: 3)
                                            )
                                        })
                                } else {
                                    Spacer()
                                        .frame(width: 80, height: 118, alignment: .center)
                                        .background(Color(red: 0.5, green: 0.5, blue: 0.5))
                                        .cornerRadius(5)
                                        .padding(3)
                                        .opacity(self._state.isAPossibleGap(card: self._selected, gap: getPositionFromHGridIndex(index: index)) ? 0.4 : 0.1)
                                        .onTapGesture {
                                            if self._selected === nil {
                                                return
                                            }
                                            
                                            let pos = self.getPositionFromHGridIndex(index: index)
                                            let m = Move(card: self._selected!, to: pos, state: self._state)
                                            self._state.performMove(move: m, verify: self._peformMovesSafely)
                                            self._selected = nil
                                            
                                            self._state.computeMoves()
                                        }
                                        .if(self._state.isAPossibleGap(card: self._selected, gap: getPositionFromHGridIndex(index: index)), transform: { view in
                                            view
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(.red, lineWidth: 3)
                                            )
                                        })
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 500, idealHeight: 500)
                
                Group {
                    LazyHGrid (rows: [GridItem(.flexible())]) {
                        ForEach(self._state.removedCards, id: \.description) {card in
                            Image("\(card.cardColor)_\(card.cardNumber)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
                .frame(maxHeight: 100)
                .opacity(0.5)
                
                HStack {
                    Button("Generate new game", action: self.generateNewGame)
                    
                    Button("Reset", action: {
                        self._selected = nil
                        self._state.reset()
                        self._depth = 0
                    })
                    
                    Button("Remove Kings", action: {
                        self._selected = nil
                        self._state.removeKings()
                        self._state.computeMoves()
                    })
                    
                    Button("Shuffle", action: {
                        self._selected = nil
                        self._state.shuffle()
                        self._state.computeMoves()
                    })
                    
                    Toggle(isOn: self.$_peformMovesSafely) {
                        Text("Apply move verification")
                    }
                }
                
                Spacer(minLength: 50)
                
                Group {
                    Text("\(self._state.moves.count) Children states found").bold()
                    ForEach(self._state.moves, id: \.state.description) { move in
                        Button(move.description, action: {
                            self._state.performMove(move: move)
                            self._depth += 1
                        })
                    }
                }
            }
        }
        .onAppear() { }
        .frame(maxWidth: .infinity)
        .padding(10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
