# Building the Matching Processor - Step by Step

This guide will help you build the goroutine-based matching processor from scratch. Type each section yourself, then I'll verify it works!

---

## Step 1: Define Order Types and Result

**What you're building:** Constants and struct to represent order types (Limit vs Market) and the result returned when submitting an order.

**Concepts:**
- `type X uint8` creates a small integer type (like an enum)
- `const ( ... )` defines constants
- `iota` auto-increments (0, 1, 2...)

**Your task:** In `processor.go`, add this after `package engine`:

```go
import (
	"errors"
)

type OrderType uint8

const (
	Limit OrderType = iota  // 0
	Market                   // 1
)

type SubmitResult struct {
	Trades []Trade
	Err    error
}
```

**What this does:**
- `OrderType` distinguishes limit orders from market orders
- `SubmitResult` holds either trades (success) or an error

---

## Step 2: Define Internal Request Structure

**What you're building:** A private struct that represents one order request sent to the worker goroutine.

**Concepts:**
- lowercase field names = private (only this package sees it)
- `chan X` = channel that carries type X

**Your task:** Add this below `SubmitResult`:

```go
type orderRequest struct {
	order     Order
	orderType OrderType
	resultCh  chan SubmitResult
}
```

**What this does:**
- Worker receives this via channel
- `resultCh` is how worker sends result back to caller

---

## Step 3: Define the Main Processor Structure

**What you're building:** The matching processor that holds the order book and communication channels.

**Concepts:**
- `*OrderBook` = pointer to order book
- `chan orderRequest` = channel for incoming requests
- `chan struct{}` = signal channel (no data, just notification)

**Your task:** Add this:

```go
type MatchingProcessor struct {
	book   *OrderBook
	reqCh  chan orderRequest
	stopCh chan struct{}
}
```

**What this does:**
- `book` = the in-memory order book
- `reqCh` = incoming order queue
- `stopCh` = signal to stop the worker

---

## Step 4: Constructor Function

**What you're building:** Factory function that creates and starts the processor.

**Concepts:**
- `make(chan X, size)` creates buffered channel
- `go func()` starts goroutine
- `return processor` gives created object to caller

**Your task:** Add this:

```go
func NewMatchingProcessor(symbol string, queueSize int) *MatchingProcessor {
	if queueSize <= 0 {
		queueSize = 1024
	}
	processor := &MatchingProcessor{
		book:   NewOrderBook(symbol),
		reqCh:  make(chan orderRequest, queueSize),
		stopCh: make(chan struct{}),
	}
	go processor.run()
	return processor
}
```

**What this does:**
- Creates order book for given symbol
- Creates buffered channel (holds up to queueSize requests)
- Starts `run()` in background goroutine
- Returns processor ready to accept orders

---

## Step 5: The Worker Loop (MOST IMPORTANT!)

**What you're building:** The goroutine that processes orders one by one.

**Concepts:**
- `for { ... }` = infinite loop
- `select { case ... }` = wait on multiple channels
- `req := <-mp.reqCh` = receive from channel
- `req.resultCh <- result` = send to channel
- `<-mp.stopCh` = receive from stop signal

**Your task:** Add this method:

```go
func (mp *MatchingProcessor) run() {
	for {
		select {
		case req := <-mp.reqCh:
			var trades []Trade
			switch req.orderType {
			case Limit:
				trades = mp.book.AddLimitOrder(req.order)
			case Market:
				trades = mp.book.AddMarketOrder(req.order)
			default:
				req.resultCh <- SubmitResult{Err: errors.New("unsupported order type")}
				continue
			}
			req.resultCh <- SubmitResult{Trades: trades}
		case <-mp.stopCh:
			return
		}
	}
}
```

**What this does (line by line):**
- `for { select { ... } }` = wait forever on channels
- `case req := <-mp.reqCh:` = when order arrives
- `switch req.orderType` = check if limit or market
- Call appropriate order book method
- Send result back via `req.resultCh`
- `case <-mp.stopCh:` = when stop signal, exit loop

**KEY INSIGHT:** This loop runs in its own goroutine, processing orders sequentially (one after another), so there's no race condition!

---

## Step 6: Submit Method (Public API)

**What you're building:** The method external code calls to submit an order.

**Concepts:**
- Creates result channel
- Sends request to worker
- Waits for result
- Returns result

**Your task:** Add this:

```go
func (mp *MatchingProcessor) Submit(order Order, orderType OrderType) SubmitResult {
	resultCh := make(chan SubmitResult, 1)
	mp.reqCh <- orderRequest{order: order, orderType: orderType, resultCh: resultCh}
	return <-resultCh
}
```

**What this does:**
- Creates a result channel (buffer size 1, so worker doesn't block)
- Packages order + type + resultCh into request
- Sends request to worker via `mp.reqCh`
- Waits for result from worker: `<-resultCh`
- Returns result to caller

**KEY INSIGHT:** This is synchronous from caller's view (waits for result), but all matching happens in the worker goroutine!

---

## Step 7: Helper Methods

**What you're building:** Read-only snapshot and stop method.

**Your task:** Add these:

```go
func (mp *MatchingProcessor) Snapshot() (symbol string, bidLevels int, askLevels int) {
	return mp.book.Symbol(), mp.book.BidLevels(), mp.book.AskLevels()
}

func (mp *MatchingProcessor) Stop() {
	close(mp.stopCh)
}
```

**What this does:**
- `Snapshot` reads current state (thread-safe because order book has mutex)
- `Stop` closes stop channel, which triggers `run()` to exit

---

## Complete Flow Diagram

```
main() calls Submit(order)
        |
        v
Submit creates resultCh
        |
        v
Submit sends {order, type, resultCh} -> reqCh
        |
        v
    [CHANNEL]
        |
        v
run() receives request from reqCh
        |
        v
run() calls book.AddLimitOrder/AddMarketOrder
        |
        v
run() sends SubmitResult -> resultCh
        |
        v
    [CHANNEL]
        |
        v
Submit receives result <- resultCh
        |
        v
Submit returns result to main()
```

---

## Now Type It!

1. Open `internal/engine/processor.go`
2. Type each step yourself (don't copy-paste—typing helps learning!)
3. After each step, let me know and I'll verify
4. When done, we'll run `go run ./cmd/engine` to test

**Ready? Start with Step 1!**
