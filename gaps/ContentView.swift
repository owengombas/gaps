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
        state.redistribute()
        state.shuffle()
        state.removeCardsRandomly(numberOfCards: 4)
        state.computeMoves()
        print(state.moves.count)
    }
    
    var body: some View {
        VStack {
            LazyHGrid(rows: items) {
                ForEach(Array(state.toArray(fromTopToBottom: true).enumerated()), id: \.offset) {index, card in
                    Text(card?.description ?? "GAP")
                }
            }
            
            Button("SHUFFLE", action: generateNewGame)
            Button("REDISTRIBUTE", action: state.redistribute)
            
            ForEach(state.moves, id: \.state.description) { move in
                Button(move.description, action: state.shuffle)
            }
            
            
        }
        .padding()
        .onAppear() { generateNewGame() }
    }
    
    init() {
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
