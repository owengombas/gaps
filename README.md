# Gaps

## Efficient weights
```swift
Heuristic.compose([
    (5, Heuristic.countMisplacedCards),
    (1, Heuristic.stuckGaps()),
    (4, Heuristic.wrongColumnPlacement)
])
```

## Interesting seeds

```
Full A* solvable (~85 seconds): 0413131415161718192021222324XX394041424344454647484950XX262728293031323334353637XX000102030405060708091011XX
```
