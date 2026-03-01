# Building Main Demo - Step by Step

This is the FINAL piece! You'll wire everything together and run the engine.

---

## Step 1: Import Required Packages

**What you're building:** Bringing in standard library and your engine.

**Your task:** In `main.go`, replace the whole file with this:

```go
package main

import (
	"fmt"
	"time"

	"axiomx/internal/engine"
)

func main() {
	// Your code will go here
}
```

**What these do:**
- `fmt` = printing output
- `time` = timestamps
- `axiomx/internal/engine` = your matching engine package

---

## Step 2: Create Matching Processor

**What you're building:** Initialize the worker goroutine for BTC-USD.

**Concepts:**
- `defer` = runs at end (cleanup)
- 2048 = channel buffer size

**Your task:** Inside `main()`, add:

```go
func main() {
	processor := engine.NewMatchingProcessor("BTC-USD", 2048)
	defer processor.Stop()
```

**What this does:**
- Creates processor for BTC-USD symbol
- Buffer size 2048 means queue can hold 2048 pending requests
- `defer processor.Stop()` ensures goroutine is stopped when main exits

---

## Step 3: Submit Two Limit Orders

**What you're building:** Add a buy and sell order that don't match.

**Concepts:**
- `30000_00` = $30,000.00 (price with 2 decimal places)
- `2_0000_0000` = 2.0 BTC (quantity with 8 decimal places)
- `time.Now().UnixNano()` = current timestamp

**Your task:** Add these lines:

```go
	processor.Submit(engine.NewOrder("o1", engine.Buy, 30000_00, 2_0000_0000, time.Now().UnixNano()), engine.Limit)
	processor.Submit(engine.NewOrder("o2", engine.Sell, 30100_00, 1_0000_0000, time.Now().UnixNano()), engine.Limit)
```

**What this does:**
- Order o1: Buy 2.0 BTC at $30,000
- Order o2: Sell 1.0 BTC at $30,100
- They don't match (buy price < sell price)
- Both rest in order book

---

## Step 4: Submit Market Order

**What you're building:** A market buy that will match the sell order.

**Concepts:**
- Market order has price 0 (matches at any price)
- Returns result with trades or error

**Your task:** Add:

```go
	result := processor.Submit(engine.NewOrder("o3", engine.Buy, 0, 1_0000_0000, time.Now().UnixNano()), engine.Market)
	if result.Err != nil {
		fmt.Printf("submit error: %v\n", result.Err)
		return
	}
```

**What this does:**
- Order o3: Market buy 1.0 BTC
- Will match against o2 (sell at $30,100)
- Check for errors
- If error, print and exit

---

## Step 5: Print Results

**What you're building:** Display book state and trades.

**Your task:** Add:

```go
	symbol, bids, asks := processor.Snapshot()
	fmt.Printf("symbol=%s bids=%d asks=%d trades=%d\n", symbol, bids, asks, len(result.Trades))
	for _, tr := range result.Trades {
		fmt.Printf("trade id=%s price=%d qty=%d maker=%s taker=%s\n", tr.ID, tr.PriceTicks, tr.Qty, tr.MakerOrderID, tr.TakerOrderID)
	}
}
```

**What this does:**
- Get book snapshot (symbol, bid/ask counts)
- Print summary
- Loop through trades and print details

---

## Complete Example

After typing all steps, your `main.go` should look like:

```go
package main

import (
	"fmt"
	"time"

	"axiomx/internal/engine"
)

func main() {
	processor := engine.NewMatchingProcessor("BTC-USD", 2048)
	defer processor.Stop()

	processor.Submit(engine.NewOrder("o1", engine.Buy, 30000_00, 2_0000_0000, time.Now().UnixNano()), engine.Limit)
	processor.Submit(engine.NewOrder("o2", engine.Sell, 30100_00, 1_0000_0000, time.Now().UnixNano()), engine.Limit)

	result := processor.Submit(engine.NewOrder("o3", engine.Buy, 0, 1_0000_0000, time.Now().UnixNano()), engine.Market)
	if result.Err != nil {
		fmt.Printf("submit error: %v\n", result.Err)
		return
	}

	symbol, bids, asks := processor.Snapshot()
	fmt.Printf("symbol=%s bids=%d asks=%d trades=%d\n", symbol, bids, asks, len(result.Trades))
	for _, tr := range result.Trades {
		fmt.Printf("trade id=%s price=%d qty=%d maker=%s taker=%s\n", tr.ID, tr.PriceTicks, tr.Qty, tr.MakerOrderID, tr.TakerOrderID)
	}
}
```

---

## Expected Output

When you run `go run ./cmd/engine`, you should see:

```
symbol=BTC-USD bids=1 asks=0 trades=1
trade id=t1 price=3010000 qty=100000000 maker=o2 taker=o3
```

**What happened:**
- o1 (buy at 30000) rests in book
- o2 (sell at 30100) rests in book
- o3 (market buy) matches o2 at 30100
- 1 bid remains (o1), 0 asks (o2 fully filled)
- 1 trade executed

---

## Now Type It!

1. Open `cmd/engine/main.go`
2. Build it step by step
3. When done, run: `go run ./cmd/engine`
4. Let me know if you see the expected output!

**This ties everything together. You're almost done!**
