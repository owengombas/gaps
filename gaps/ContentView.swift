//
//  ContentView.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var state: GameState = GameState()
    @State var depth = 0
    @State var selected: Card? = nil
    
    var items: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    func generateNewGame() {
        depth = 0
        state.reset()
        state.shuffle()
        state.removeKings()
        state.computeMoves()
        print(state.moves.count)
    }
    
    func getPositionFromHGridIndex(index: Int) -> (Int, Int) {
        let line = index % self.state.lines
        let column = Int(floor(Double(index) / Double(self.state.lines)))
        return (column, line)
    }
    
    var body: some View {
        VStack {
            ScrollView {
                
                Text("Gaps").font(.system(size: 20)).bold()
                
                Spacer(minLength: 20)
                
                Text("Depth: \(depth)")
                Group {
                    LazyHGrid(rows: items) {
                        ForEach(Array(state.toArray(fromTopToBottom: true).enumerated()), id: \.offset) {index, card in
                            Group {
                                if card != nil {
                                    Image("\(card!.cardColor)_\(card!.cardNumber)")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .onTapGesture {
                                            self.selected = card
                                        }
                                        .padding(3)
                                        .cornerRadius(5)
                                        .if(self.selected === card, transform: { view in
                                            view.overlay(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(.blue, lineWidth: 3)
                                            )
                                        })
                                        
                                } else {
                                    Spacer()
                                        .frame(width: 80, height: 118, alignment: .center)
                                        .background(Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5))
                                        .cornerRadius(10)
                                        .onTapGesture {
                                            if self.selected == nil {
                                                return
                                            }
                                            
                                            let pos = self.getPositionFromHGridIndex(index: index)
                                            print("test", pos)
                                            let m = Move(card: self.selected!, to: pos, state: self.state)
                                            self.state.performMove(move: m)
                                            self.selected = nil
                                            
                                            self.state.computeMoves()
                                        }
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 500, idealHeight: 500)
                
                Group {
                    LazyHGrid (rows: [GridItem(.flexible())]) {
                        ForEach(state.removedCards, id: \.description) {card in
                            Image("\(card.cardColor)_\(card.cardNumber)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
                .frame(maxHeight: 100)
                .opacity(0.5)
                
                HStack {
                    Button("Generate new game", action: generateNewGame)
                    Button("Reset", action: {
                        state.reset()
                        depth = 0
                    })
                    Button("Remove Kings", action: state.removeKings)
                    Button("Shuffle", action: {
                        state.shuffle()
                        state.computeMoves()
                    })
                    Button("Finds moves", action: state.computeMoves)
                }
                
                Spacer(minLength: 50)
                
                Group {
                    Text("\(state.moves.count) Children states found").bold()
                    ForEach(state.moves, id: \.state.description) { move in
                        Button(move.description, action: {
                            state.performMove(move: move)
                            depth += 1
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
