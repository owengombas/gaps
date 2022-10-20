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
    private var _lines: Int
    
    var description: String {
        get {
            var s = "(\(self._columns)x\(self._lines))\n"
            
            for j in 0 ..< _lines {
                for i in 0 ..< _columns {
                    s += String(describing: getElement(i: i, j: j)) + " "
                }
                s += "\n\n"
            }
            
            return s
        }
    }
    
    var capacity: Int {
        get { return self._columns * self._lines }
    }
    
    var columns: Int {
        get { return self._columns }
    }
    
    var lines: Int {
        get { return self._columns }
    }
    
    init(columns: Int, lines: Int, defaultValue: (Int, Int, Int) -> T) {
        self._repr = []
        self._columns = columns
        self._lines = lines
        
        var c = 0
        for j in 0..<lines {
            self._repr.append([])
            for i in 0..<columns {
                let v = defaultValue(i, j, c)
                self._repr[j].append(v)
                
                c += 1
            }
        }
    }
    
    func copy() -> Matrix<T> {
        return Matrix<T>(
            columns: self._columns,
            lines: self._lines,
            defaultValue: {(i, j, _) in
                return self.getElement(i: i, j: j)
            }
        )
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
        self._repr[j][i] = value
    }
    
    func setElement(position: (Int, Int), value: T) {
        self.setElement(i: position.0, j: position.1, value: value)
    }
    
    func setElement(number: Int, value: T) {
        let pos = self.getPositionFrom(index: number)
        return self.setElement(i: pos.0, j: pos.1, value: value)
    }
    
    func shuffle() {
        for i in 0..<self.capacity {
            let j = Int.random(in: i..<self.capacity)
            
            let iPos: (Int, Int) = self.getPositionFrom(index: i)
            let jPos: (Int, Int) = self.getPositionFrom(index: j)
            
            self.swap(from: iPos, to: jPos)
        }
    }
    
    func getPositionFrom(index: Int) -> (Int, Int) {
        let column = index % self._columns
        let line = Int(floor(Double(index) / Double(self._columns)))
        return (column, line)
    }
    
    func swap(iFrom: Int, jFrom: Int, iTo: Int, jTo: Int) {
        let e1 = getElement(i: iFrom, j: jFrom)
        let e2 = getElement(i: iTo, j: jTo)
        setElement(i: iTo, j: jTo, value: e1)
        setElement(i: iFrom, j: jFrom, value: e2)
    }
    
    func swap(from: (Int, Int), to: (Int, Int)) {
        self.swap(iFrom: from.0, jFrom: from.1, iTo: to.0, jTo: to.1)
    }
    
    func setElements(value: (Int, Int, T, Int) -> T) {
        self.forEach(cb: {(i, j, v, c) in
            let newValue = value(i, j, v, c)
            self.setElement(i: i, j: j, value: newValue)
        })
    }
    
    func map(cb: (Int, Int, T, Int) -> (T)) -> Matrix<T> {
        let copy = self.copy()
        
        copy.forEach(cb: { (i, j, v, c) in
            copy.setElement(i: i, j: j, value: cb(i, j, v, c))
        })
        
        return copy
    }
    
    func findPositions(condition: (Int, Int, T, Int) -> Bool) -> [(Int, Int)] {
        var positions: [(Int, Int)] = []
        
        self.forEach(cb: {(i, j, v, c) in
            if condition(i, j, v, c) {
                positions.append((i, j))
            }
        })
        
        return positions
    }
    
    func findOnePosition(condition: (Int, Int, T, Int) -> Bool) -> (Int, Int)? {
        let positions = findPositions(condition: condition)
        if positions.count >= 1 { return positions[0] }
        return nil
    }
    
    func forEach(cb: (Int, Int, T, Int) -> ()) {
        DispatchQueue.global(qos: .background).sync {
            var count = 0
            for j in 0 ..< _lines {
                for i in 0 ..< _columns {
                    cb(i, j, getElement(i: i, j: j), count)
                    count += 1
                }
            }
        }
    }
    
    func forEachTopBottom(cb: (Int, Int, T, Int) -> ()) {
        DispatchQueue.global(qos: .background).sync {
            var count = 0
            for i in 0 ..< _columns {
                for j in 0 ..< _lines {
                    cb(i, j, getElement(i: i, j: j), count)
                    count += 1
                }
            }
        }
    }
    
    func forEachSync(cb: (Int, Int, T, Int) -> (), lineChangedCb: (Int, Int) -> () = {(_, _) in }) {
        var count = 0
        for j in 0 ..< _lines {
            for i in 0 ..< _columns {
                cb(i, j, getElement(i: i, j: j), count)
                count += 1
            }
            lineChangedCb(j, count)
        }
    }
    
    func forEachTopBottomSync(cb: (Int, Int, T, Int) -> (), columnChangedCb: (Int, Int) -> () = {(_, _) in }) {
        var count = 0
        for i in 0 ..< _columns {
            for j in 0 ..< _lines {
                cb(i, j, getElement(i: i, j: j), count)
                count += 1
            }
            columnChangedCb(i, count)
        }
    }
    
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
