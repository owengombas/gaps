//
//  StateUI.swift
//  gaps
//
//  Created by owen on 22.11.22.
//

import SwiftUI

struct StateUI: View {
    @StateObject var state: GameState
    @Binding var selected: Card?
    @Binding var peformMovesSafely: Bool
    
    var onCardChange: ((Card, (Int, Int)) -> Void)?
    
    func getPositionFromHGridIndex(index: Int) -> (Int, Int) {
        let line = index % self.state.rows
        let column = Int(floor(Double(index) / Double(self.state.rows)))
        return (column, line)
    }
    
    func onCardTap(card: Card?) {
        if self.selected === nil {
            self.selected = card
        } else if self.selected === card {
            self.selected = nil
        }
    }
    
    func onGapTap(index: Int) {
        if self.selected === nil {
            return
        }
        
        let pos = self.getPositionFromHGridIndex(index: index)
        let m = Move(card: self.selected!, to: pos, state: self.state)
        
        self.state.performMove(move: m, verify: self.peformMovesSafely)
        self.state.computeMoves()
        
        self.onCardChange?(self._selected.wrappedValue!, pos)
        
        self.selected = nil
    }
    
    var body: some View {        
        VStack {
            Text("Cost: \(self.state.cost)").font(.system(size: 20)).bold()
            
            Group {
                LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: self.state.rows)) {
                    ForEach(Array(self.state.toArray(fromTopToBottom: true).enumerated()), id: \.offset) {index, card in
                        Group {
                            if card != nil {
                                // A Card
                                Image("\(card!.cardColor)_\(card!.cardNumber)")
                                    .resizable()
                                    .frame(width: 80, height: 118)
                                    .aspectRatio(contentMode: .fit)
                                    .onTapGesture { self.onCardTap(card: card) }
                                    .padding(3)
                                    .cornerRadius(5)
                                    .if(self.selected === card, transform: { view in
                                        view.overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(.blue, lineWidth: 3)
                                        )
                                    })
                                    .if(self.state.isMovable(card: card!) && self.selected === nil, transform: { view in
                                        view.overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(.red, lineWidth: 3)
                                        )
                                    })
                            } else {
                                // A GAP
                                Spacer()
                                    .frame(width: 80, height: 118, alignment: .center)
                                    .background(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    .cornerRadius(5)
                                    .padding(3)
                                    .opacity(self.state.isAPossibleGap(card: self.selected, gap: getPositionFromHGridIndex(index: index)) ? 0.4 : 0.1)
                                    .onTapGesture { self.onGapTap(index: index) }
                                    .if(self.state.isAPossibleGap(card: self.selected, gap: getPositionFromHGridIndex(index: index)), transform: { view in
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
            .frame(
                minHeight: CGFloat(self.state.rows * 130)
            )
            
            Group {
                LazyHGrid (rows: [GridItem(.flexible())]) {
                    ForEach(self.state.removedCards, id: \.description) {card in
                        Image("\(card.cardColor)_\(card.cardNumber)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
            .frame(maxHeight: 100)
            .opacity(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }
}

struct StateUI_Previews: PreviewProvider {
    static var previews: some View {
        Text("No")
    }
}