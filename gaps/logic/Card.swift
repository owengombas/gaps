//
//  File.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class Card: CustomStringConvertible {
    private var _cardNumber: CardNumbers
    private var _cardColor: CardColors
    
    var description: String {
        get {
            return "(\(self._cardNumber), \(self._cardColor), \(self.number))"
        }
    }
    
    init(color: CardColors, number: CardNumbers) {
        self._cardColor = color
        self._cardNumber = number
    }
    
    var cardColor: CardColors {
        get { return self._cardColor }
    }
    
    var cardNumber: CardNumbers {
        get { return self._cardNumber }
    }
    
    var number: Int {
        get {
            return self._cardColor.rawValue + self._cardNumber.rawValue
        }
    }
    
    /**
     Get the higher rank card from the same color
     */
    var higher: Card? {
        let n: CardNumbers? = CardNumbers.init(rawValue: self.cardNumber.rawValue + 1)
        
        if n == nil { return nil }
        
        return Card(color: self._cardColor, number: n!)
    }
    
    /**
     Each card has an attributed number from 0 to 51
     ♣  [0, 12] - CLUB
     ♦ [13, 25] - DIAMOND
     ♥ [26, 38] - HEART
     ♠ [39, 51] - SPADE
     */
    public static func fromNumber(number: Int) -> Card {
        assert(number >= 0, "The number should be greater than 0")
        assert(number <= 51, "The number should be smaller than 51")
        
        var cardColor: CardColors? = nil
        
        for color in CardColors.allCases {
            if (color.rawValue...color.rawValue + 12).contains(number) {
                cardColor = color
                break
            }
        }
        
        let n = Int((number) % 13)
        let cardNumber: CardNumbers? = CardNumbers(rawValue: n)
        
        return Card(color: cardColor!, number: cardNumber!)
    }
    
    /**
     Are two card equals, value based
     */
    func isEquals(to: Card?) -> Bool {
        return (
            self.cardNumber == to?.cardNumber &&
            self.cardColor == to?.cardColor
        )
    }
}
