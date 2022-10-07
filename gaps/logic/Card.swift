//
//  File.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class Card {
    private var _color: CardColors
    private var _number: CardNumbers
    
    init(_color: CardColors, _number: CardNumbers) {
        self._color = _color
        self._number = _number
    }
    
    public var color: CardColors {
        get { return self._color }
    }
    
    public var number: CardNumbers {
        get { return self._number }
    }
}
