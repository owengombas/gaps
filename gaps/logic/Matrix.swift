//
//  Matrix.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

class Matrix<T>: CustomStringConvertible, ObservableObject {
    @Published private var _repr: [[T]]
    private var _columns: Int
    private var _rows: Int
    private var _defaultValue: (Int, Int, Int) -> T
    
    var description: String {
        get {
            var s = "(\(self._columns)x\(self._rows))\n"
            
            for j in 0 ..< self._rows {
                for i in 0 ..< self._columns {
                    s += String(describing: self.getElement(i: i, j: j)) + " "
                }
                s += "\n\n"
            }
            
            return s
        }
    }
    
    var capacity: Int {
        get { return self._columns * self._rows }
    }
    
    var columns: Int {
        get { return self._columns }
        set {
            self._columns = newValue
            refresh()
        }
    }
    
    var rows: Int {
        get { return self._rows }
        set {
            self._rows = newValue
            refresh()
        }
    }
    
    private func refresh() {
        var c = 0
        for j in 0..<rows {
            self._repr.append([])
            
            for i in 0..<columns {
                let v = self._defaultValue(i, j, c)
                self._repr[j].append(v)
                
                c += 1
            }
        }
    }
    
    init(columns: Int, rows: Int, defaultValue: @escaping (Int, Int, Int) -> T) {
        self._repr = []
        self._columns = columns
        self._rows = rows
        self._defaultValue = defaultValue
        
        refresh()
    }
    
    /**
     Get a copy off the matrix
     */
    func copy() -> Matrix<T> {
        return Matrix<T>(
            columns: self._columns,
            rows: self._rows,
            defaultValue: {(i, j, _) in
                return self.getElement(i: i, j: j)
            }
        )
    }

    func copy(from: Matrix<T>) {        
        self._columns = from._columns
        self._rows = from._rows
        
        self.forEach(cb: { i, j, card, c in
            self.setElement(i: i, j: j, value: from.getElement(i: i, j: j))
        })
    }
    
    func getElement(i: Int, j: Int) -> T {
        return self._repr[j][i]
    }
    
    func getElement(position: (Int, Int)) -> T {
        return getElement(i: position.0, j: position.1)
    }
    
    func getElement(number: Int) -> T {
        let pos = self.getPositionFrom(index: number)
        return self.getElement(i: pos.0, j: pos.1)
    }
    
    func setElement(i: Int, j: Int, value: T) {
        DispatchQueue.main.async {
            self._repr[j][i] = value
        }
    }
    
    func setElement(position: (Int, Int), value: T) {
        self.setElement(i: position.0, j: position.1, value: value)
    }
    
    func setElement(number: Int, value: T) {
        let pos = self.getPositionFrom(index: number)
        return self.setElement(i: pos.0, j: pos.1, value: value)
    }
    
    /**
     Set all elements to a value
     */
    func setElements(value: (Int, Int, T, Int) -> T) {
        self.forEach(cb: {(i, j, v, c) in
            let newValue = value(i, j, v, c)
            self.setElement(i: i, j: j, value: newValue)
        })
    }
    
    /**
     Shuffle values in the matrix
     */
    func shuffle() {
        for i in 0..<self.capacity {
            let j = Int.random(in: i..<self.capacity)
            
            let iPos: (Int, Int) = self.getPositionFrom(index: i)
            let jPos: (Int, Int) = self.getPositionFrom(index: j)
            
            self.swap(posA: iPos, posB: jPos)
        }
    }
    
    /**
     Get a (i, j) position from a index based on the flatten matrix
     [
       [a, b, c]
       [d, e, f]
     ]
     to
     [a, b, c, d, e, f]
     */
    func getPositionFrom(index: Int) -> (Int, Int) {
        let column = index % self._columns
        let line = Int(floor(Double(index) / Double(self._columns)))
        return (column, line)
    }
    
    /**
     Swap two values at specified positions in the matrix
     */
    func swap(i1: Int, i2: Int, j1: Int, j2: Int) {
        let e1 = self.getElement(i: i1, j: i2)
        let e2 = self.getElement(i: j1, j: j2)
        self.setElement(i: j1, j: j2, value: e1)
        self.setElement(i: i1, j: i2, value: e2)
    }
    
    /**
     Swap two values at specified positions in the matrix
     */
    func swap(posA: (Int, Int), posB: (Int, Int)){
        self.swap(i1: posA.0, i2: posA.1, j1: posB.0, j2: posB.1)
    }
    
    /**
     Perform async map
     */
    func map(cb: (Int, Int, T, Int) -> (T)) -> Matrix<T> {
        let copy = self.copy()
        
        copy.forEach(cb: { (i, j, v, c) in
            copy.setElement(i: i, j: j, value: cb(i, j, v, c))
        })
        
        return copy
    }
    
    /**
     Find positions based on a condition
     */
    func findPositions(condition: (Int, Int, T, Int) -> Bool) -> [(Int, Int)] {
        var positions: [(Int, Int)] = []
        
        self.forEach(cb: {(i, j, v, c) in
            if condition(i, j, v, c) {
                positions.append((i, j))
            }
        })
        
        return positions
    }
    
    /**
     Find first position based on a condition
     */
    func findOnePosition(condition: (Int, Int, T, Int) -> Bool) -> (Int, Int)? {
        let positions = self.findPositions(condition: condition)
        if positions.count >= 1 { return positions[0] }
        return nil
    }
    
    /**
     Perform an async forEach loop from left to right order
     */
    func forEach(cb: (Int, Int, T, Int) -> ()) {
        DispatchQueue.global(qos: .background).sync {
            var count = 0
            for j in 0 ..< self._rows {
                for i in 0 ..< self._columns {
                    cb(i, j, self.getElement(i: i, j: j), count)
                    count += 1
                }
            }
        }
    }
    
    /**
     Perform an async forEach loop from top to bottom order
     */
    func forEachTopBottom(cb: (Int, Int, T, Int) -> ()) {
        DispatchQueue.global(qos: .background).sync {
            var count = 0
            for i in 0 ..< self._columns {
                for j in 0 ..< self._rows {
                    cb(i, j, self.getElement(i: i, j: j), count)
                    count += 1
                }
            }
        }
    }
    
    /**
     Perform a synchronous forEach loop from left to right order
     */
    func forEachSync(cb: (Int, Int, T, Int) -> (), lineChangedCb: (Int, Int) -> () = {(_, _) in }) {
        var count = 0
        for j in 0 ..< self._rows {
            for i in 0 ..< self._columns {
                cb(i, j, self.getElement(i: i, j: j), count)
                count += 1
            }
            lineChangedCb(j, count)
        }
    }
    
    /**
     Perform a synchronous forEach loop from top to bottom order
     */
    func forEachTopBottomSync(cb: (Int, Int, T, Int) -> (), columnChangedCb: (Int, Int) -> () = {(_, _) in }) {
        var count = 0
        for i in 0 ..< self._columns {
            for j in 0 ..< self._rows {
                cb(i, j, self.getElement(i: i, j: j), count)
                count += 1
            }
            columnChangedCb(i, count)
        }
    }
    
    /**
     Flatten the matrix and convert it to a single array
     @param fromTopToBottom Order the values for them to match the top to bottom order
     */
    func toArray(fromTopToBottom: Bool = false) -> [T] {
        var arr: [T] = []
        
        if fromTopToBottom {
            self.forEachTopBottom(cb: {(i: Int, j: Int, v: T, c: Int) in
                arr.insert(self.getElement(i: i, j: j), at: c)
            })
        } else {
            self.forEach(cb: {(i: Int, j: Int, v: T, c: Int) in
                arr.insert(self.getElement(i: i, j: j), at: c)
            })
        }
        
        return arr
    }
}
