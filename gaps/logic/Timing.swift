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

    /**
     Get the time elapsed since the timer was started
     */
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

    /**
     Start the timer
     - Parameters:
       - interval: time interval after which the timer triggers
       - callback: callback function to be called when the timer triggers
     - Returns: the timer
     */
    func start(interval: TimeInterval, _ callback: @escaping () -> Void) -> Timing {
        self._start = Date()
        
        self._timer = Foundation.Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            callback()
        }
        
        return self
    }

    /**
     Start the timer
     - Returns: the timer
     */
    func start() -> Timing {
        self._start = Date()
        
        return self
    }

    /**
     Stop the timer
     - Returns: the timer
     */
    func stop() -> Timing {
        self._end = Date()
        self._timer?.invalidate()

        return self
    }

    /**
     Reset the timer
     */
    func reset() {
        self._start = nil
        self._end = nil
    }

    /**
     Wait for n seconds
     - Parameter seconds: number of seconds to wait
     */
    static func wait(seconds: Double) async {
        try! await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
