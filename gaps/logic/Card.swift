//
//  File.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class Card: CustomStringConvertible {
    private var _rank: CardRank
    private var _suit: CardSuit
    
    var description: String {
        get {
            return "(\(self._rank), \(self._suit))"
        }
    }
    
    init(suit: CardSuit, rank: CardRank) {
        self._suit = suit
        self._rank = rank
    }
    
    /**
     The suit of the card (Diamonds, Club, Heart, Spade)
     */
    var suit: CardSuit {
        get { return self._suit }
    }
    
    /**
     The card rank from Ace to King
     */
    var rank: CardRank {
        get { return self._rank }
    }
    
    /**
     The number that represents the card in the deck from 0 to 51 (4 \* 13 - 1)
     */
    func toNumber(columns: Int = 13) -> Int {
        return self._suit.rawValue * columns + self._rank.rawValue
    }
    
    /**
     Get the higher rank card from the same color
     */
    var higher: Card? {
        let n: CardRank? = CardRank.init(rawValue: self.rank.rawValue + 1)
        
        if n == nil { return nil }
        
        return Card(suit: self._suit, rank: n!)
    }
    
    var lower: Card? {
        let n: CardRank? = CardRank.init(rawValue: self.rank.rawValue - 1)
        
        if n == nil { return nil }
        
        return Card(suit: self._suit, rank: n!)
    }
    
    /**
     Each card has an attributed number from 0 to 51
     ♣ [0, 12] - CLUB
     ♦ [13, 25] - DIAMOND
     ♥ [26, 38] - HEART
     ♠ [39, 51] - SPADE
     */
    public static func fromNumber(number: Int, columns: Int = 13, rows: Int = 4) -> Card {
        assert(number >= 0, "The number should be greater than 0")
        assert(number <= 51, "The number should be smaller than 51")

        let suit: CardSuit = CardSuit.init(rawValue: number / columns)!
        let rank: CardRank = CardRank.init(rawValue: number % columns)!

        return Card(suit: suit, rank: rank)
    }

    public static func fromPosition(position: (Int, Int), columns: Int = 13, rows: Int = 4) -> Card {
        let number = position.0 + position.1 * columns
        return Card.fromNumber(number: number, columns: columns, rows: rows)
    }
    
    /**
     Are two card equals, value based
     */
    func isEquals(to: Card?) -> Bool {        
        return (
            self.rank == to?.rank &&
            self.suit == to?.suit
        )
    }

    /**
     Is the rank of card that is the 
     */
    func isHigher(to: Card?) -> Bool {
        return (
            self.rank.rawValue > to?.rank.rawValue ?? 0 &&
            self.suit == to?.suit
        )
    }

    func isStrictlyOneHigher(to: Card?) -> Bool {
        return (
            self.rank.rawValue == to?.rank.rawValue ?? 0 + 1 &&
            self.suit == to?.suit
        )
    }
}
