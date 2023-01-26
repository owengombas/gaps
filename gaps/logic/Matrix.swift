//
//  Matrix.swift
//  gaps
//
//  Created by owen on 05.10.22.
//

import Foundation

/**
 A matrix data structure
 */
class Matrix<T>: CustomStringConvertible, ObservableObject {
    private var _values: [[T]]
    private var _columns: Int
    private var _rows: Int
    private var _defaultValue: (Int, Int, Int, Matrix<T>) -> T

    /**
     The string representation of the matrix
     */
    var description: String {
        get {
            var s = "(\(self._columns)x\(self._rows))\n"
            
            for j in 0 ..< self._rows {
                for i in 0 ..< self._columns {
                    s += String(describing: self.getElement(column: i, row: j)) + " "
                }
                s += "\n\n"
            }
            
            return s
        }
    }

    /**
     The values of the matrix as a 2D array
     */
    var values: [[T]] {
        get {
            return self._values
        }
    }

    /**
     The capacity of the matrix (columns * rows)
     */
    var capacity: Int {
        get { return self._columns * self._rows }
    }
    
    var columns: Int {
        get { return self._columns }
        set {
            self._columns = newValue
            self.refresh()
        }
    }
    
    var rows: Int {
        get { return self._rows }
        set {
            self._rows = newValue
            self.refresh()
        }
    }
    
    init(columns: Int, rows: Int, defaultValue: @escaping (Int, Int, Int, Matrix<T>) -> T) {
        self._values = []
        self._columns = columns
        self._rows = rows
        self._defaultValue = defaultValue
        
        self.refresh()
    }

    /**
     Refresh the values with the default value function
     */
    func refresh() {
        var c = 0
        
        for j in 0..<self.rows {            
            self._values.append([])
            
            for i in 0..<self.columns {
                let v = self._defaultValue(i, j, c, self)
                
                self._values[j].append(v)
                
                c += 1
            }
        }
    }

    /**
     Remove the element of the matrix and refresh the values
     */
    func reset() {
        self._values.removeAll(keepingCapacity: true)
        self.refresh()
    }
    
    /**
     Get a copy off the matrix
     */
    func copy() -> Matrix<T> {
        return Matrix<T>(
            columns: self._columns,
            rows: self._rows,
            defaultValue: {(i, j, _, _) in
                return self.getElement(column: i, row: j)
            }
        )
    }

    /**
     Copy the given matrix into the current matrix
     - Parameter from: The matrix to copy from
     */
    func copy(from: Matrix<T>) {
        self._columns = from._columns
        self._rows = from._rows
        
        self.forEach {i, j, card, c, m in
            self.setElement(column: i, row: j, value: from.getElement(column: i, row: j))
        }
    }

    /**
     Get the element at the given column and row
     - Parameters:
       - column: The column of the element
       - row: The row of the element
     - Returns: The element at the given column and row
     */
    func getElement(column: Int, row: Int) -> T {
        return self._values[row][column]
    }

    /**
     Get the element at the given position
     - Parameters:
       - position: The position of the element
     - Returns: The element at the given position
     */
    func getElement(position: (Int, Int)) -> T {
        return getElement(column: position.0, row: position.1)
    }

    /**
     Get the element at the given position as a index in the flattened matrix
     - Parameters:
       - number: The index in the flattened matrix
     - Returns: The element at the given index
     */
    func getElement(number: Int) -> T {
        let pos = self.getPositionFrom(index: number)
        return self.getElement(column: pos.0, row: pos.1)
    }

    /**
     Set the element at the given column and row
     - Parameters:
       - column: The column of the element
       - row: The row of the element
       - value: The value to set
     */
    func setElement(column: Int, row: Int, value: T) {
        self._values[row][column] = value
    }

    /**
     Set the element at the given position
     - Parameters:
       - position: The position of the element
       - value: The value to set
     */
    func setElement(position: (Int, Int), value: T) {
        self.setElement(column: position.0, row: position.1, value: value)
    }


    /**
     Set the element at the given position as a index in the flattened matrix
     - Parameters:
       - number: The index in the flattened matrix
       - value: The value to set
     */
    func setElement(number: Int, value: T) {
        let pos = self.getPositionFrom(index: number)
        return self.setElement(column: pos.0, row: pos.1, value: value)
    }
    
    /**
     Set all elements to a value using a function
    - Parameters:
        - value: The value function (column, row, value, count) -> newValue
     */
    func setElements(value: (Int, Int, T, Int) -> T) {
        self.forEach {i, j, v, c, m in
            let newValue = value(i, j, v, c)
            self.setElement(column: i, row: j, value: newValue)
        }
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
        let e1 = self.getElement(column: i1, row: i2)
        let e2 = self.getElement(column: j1, row: j2)
        self.setElement(column: j1, row: j2, value: e1)
        self.setElement(column: i1, row: i2, value: e2)
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
    func map(cb: (Int, Int, T, Int) -> T) -> Matrix<T> {
        let copy = self.copy()
        
        copy.forEach {i, j, v, c, m in
            copy.setElement(column: i, row: j, value: cb(i, j, v, c))
        }
        
        return copy
    }
    
    /**
     Find positions based on a condition
     */
    func findPositions(condition: (Int, Int, T, Int) -> Bool) -> [(Int, Int)] {
        var positions: [(Int, Int)] = []
        
        self.forEach {i, j, v, c, m in
            if condition(i, j, v, c) {
                positions.append((i, j))
            }
        }
        
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
    func forEach(_ cb: (Int, Int, T, Int, Matrix<T>) -> ()) {
        var count = 0

        for j in 0 ..< self._rows {
            for i in 0 ..< self._columns {
                cb(i, j, self.getElement(column: i, row: j), count, self)
                count += 1
            }
        }
    }
    
    /**
     Perform an async forEach loop from top to bottom order
     */
    func forEachTopBottom(_ cb: (Int, Int, T, Int, Matrix<T>) -> ()) {
        var count = 0
        for i in 0 ..< self._columns {
            for j in 0 ..< self._rows {
                cb(i, j, self.getElement(column: i, row: j), count, self)
                count += 1
            }
        }
    }
}
