//
//  Matrix.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class Matrix<T> {
    private var _repr: [[T?]]
    private var _columns: Int
    private var _lines: Int
    
    init(columns: Int, lines: Int) {
        self._repr = [[]]
        self._columns = columns
        self._lines = lines
        self._repr.reserveCapacity(lines)
        
        for i in 0 ..< lines {
            self._repr[i].reserveCapacity(columns)
        }
    }
    
    func getElement(i: Int, j: Int) -> T? {
        return self._repr[j][j]
    }
    
    func setElement(i: Int, j: Int, value: T?) {
        self._repr[j][j] = value
    }
    
    func map(cb: (Int, Int, T?) -> (T?)) {
        forEach(cb: { (i, j, v) in
            setElement(i: i, j: j, value: cb(j, i, v))
        })
    }
    
    func forEach(cb: (Int, Int, T?) -> ()) {
        for j in 0 ..< _lines {
            for i in 0 ..< _columns {
                cb(i, j, getElement(i: i, j: j))
            }
        }
    }
}
