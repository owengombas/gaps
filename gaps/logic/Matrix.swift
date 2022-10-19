//
//  Matrix.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class Matrix<T>: CustomStringConvertible {
    private var _repr: [[T?]]
    private var _columns: Int
    private var _lines: Int
    
    var description: String {
        get {
            var s = "(\(self._columns)x\(self._lines))\n"
            
            for j in 0 ..< _lines {
                for i in 0 ..< _columns {
                    s += String(describing: getElement(i: i, j: j)!)
                }
                s += "\n\n"
            }
            
            return s
        }
    }
    
    init(columns: Int, lines: Int) {
        self._repr = []
        self._columns = columns
        self._lines = lines
        
        for i in 0..<lines {
            self._repr.append([])
            for _ in 0..<columns {
                self._repr[i].append(nil)
            }
        }
    }
    
    func copy() -> Matrix<T> {
        let m = Matrix<T>(columns: self._columns, lines: self._lines)
        
        self.map(cb: {(i, j, v, _) in
            return m.getElement(i: i, j: j)
        })
        
        return m
    }
    
    func getElement(i: Int, j: Int) -> T? {
        return self._repr[j][i]
    }
    
    func getElement(number: Int) -> T? {
        let pos = self.getIJPosition(from: number)
        return self.getElement(i: pos.0, j: pos.1)
    }
    
    func setElement(i: Int, j: Int, value: T?) {
        self._repr[j][i] = value
    }
    
    func setElement(number: Int, value: T?) {
        let pos = self.getIJPosition(from: number)
        return self.setElement(i: pos.0, j: pos.1, value: value)
    }
    
    func getIJPosition(from: Int) -> (Int, Int) {
        let column = from % self._columns
        let line = Int(floor(Double(from) / Double(self._columns)))
        return (column, line)
    }
    
    func swap(i1: Int, j1: Int, i2: Int, j2: Int) {
        let e1 = getElement(i: i1, j: j1)
        let e2 = getElement(i: i2, j: j2)
        setElement(i: i2, j: j2, value: e1)
        setElement(i: i1, j: j1, value: e2)
    }
    
    func setAllElements(value: T?) {
        self.map(cb: {(_, _, _, _) in
            return value
        })
    }
    
    func map(cb: (Int, Int, T?, Int) -> (T?)) {
        forEach(cb: { (i, j, v, c) in
            setElement(i: i, j: j, value: cb(i, j, v, c))
        })
    }
    
    func forEach(cb: (Int, Int, T?, Int) -> ()) {
        var count = 0
        for j in 0 ..< _lines {
            for i in 0 ..< _columns {
                cb(i, j, getElement(i: i, j: j), count)
                count += 1
            }
        }
    }
}
