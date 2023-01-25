//
//  GTimer.swift
//  gaps
//
//  Created by owen on 25.01.23.
//

import Foundation

/**
 Timer that triggers an event after a given time interval
 */
class Timing {
    private var _timer: Foundation.Timer?
    private var _start: Date?
    private var _end: Date? = nil

    var elapsedTime: TimeInterval {
        if self._start == nil {
            return 0
        }

        if let start = _start, let end = _end {
            return end.timeIntervalSince(start)
        } else if let start = _start {
            return Date().timeIntervalSince(start)
        }

        return 0
    }

    func start(interval: TimeInterval, _ callback: @escaping () -> Void) -> Timing {
        self._start = Date()
        
        self._timer = Foundation.Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            callback()
        }
        
        return self
    }
    
    func start() -> Timing {
        self._start = Date()
        
        return self
    }

    func stop() -> Timing {
        self._end = Date()
        self._timer?.invalidate()

        return self
    }

    func reset() {
        self._start = nil
        self._end = nil
    }

    static func wait(seconds: Double) async {
        try! await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
