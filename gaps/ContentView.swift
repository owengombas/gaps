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
    
    var body: some View {
        VStack {
            ScrollView {
                
                Text("Gaps").font(.system(size: 20)).bold()
                
                Spacer(minLength: 20)
                
                Text("Depth: \(depth)")
                Group {
                    LazyHGrid(rows: items) {
                        ForEach(Array(state.toArray(fromTopToBottom: true).enumerated()), id: \.offset) {index, card in
                            if card != nil {
                                Image("\(card!.cardColor)_\(card!.cardNumber)")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Spacer()
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
