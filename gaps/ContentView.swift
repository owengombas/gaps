//
//  ContentView.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var state: State = State()
    
    var items: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    func generateNewGame() {
        state.reset()
        state.shuffle()
        state.removeKings()
        state.computeMoves()
        print(state.moves.count)
    }
    
    var body: some View {
        VStack {
            Group {
                LazyHGrid(rows: items) {
                    ForEach(Array(state.toArray(fromTopToBottom: true).enumerated()), id: \.offset) {index, card in
                        Text(card?.description ?? "GAP").font(.system(size: 10))
                    }
                }
            }
            
            Spacer()
            
            Button("Generate new game", action: generateNewGame)
            
            Spacer()
            
            Group {
                Button("Organize", action: state.reset)
                Button("Remove Kings", action: state.removeKings)
                Button("Shuffle", action: state.shuffle)
                Button("Finds moves", action: state.computeMoves)
            }
            
            Spacer()
            
            Group {
                Text("\(state.moves.count) STATE CHILDREN FOUND:")
                ForEach(state.moves, id: \.state.description) { move in
                    Button(move.description, action: state.shuffle)
                }
            }
            
            Spacer()
            
            Group {
                Text("REMOVED CARDS:")
                ForEach(state.removedCards, id: \.description) {card in
                    Text(card.description)
                }
            }
        }
        .onAppear() { }
    }
    
    init() {
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
