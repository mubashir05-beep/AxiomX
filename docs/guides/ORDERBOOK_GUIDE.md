# Building the Order Book - Step by Step

This is the CORE matching engine logic. Take your time and understand each part!

---

## Step 1: Import Required Packages

**What you're building:** Bringing in Go standard library functions.

**Your task:** In `orderbook.go`, add this after `package engine`:

```go
import (
	"fmt"
	"sort"
	"sync"
	"time"
)
```

**What these do:**
- `fmt` = formatting (like `fmt.Sprintf`)
- `sort` = sorting slices
- `sync` = mutex for thread safety
- `time` = timestamps

---

## Step 2: Define Price Level

**What you're building:** A price level holds all orders at one price.

**Concepts:**
- lowercase struct name = private (only this package)
- `[]Order` = slice of orders (dynamic array)

**Your task:** Add this:

```go
type priceLevel struct {
	price  int64
	orders []Order
}
```

**What this does:**
- Groups all orders at same price
- Orders are FIFO (first in, first out)

---

## Step 3: Define Order Book Structure

**What you're building:** The main order book with bid/ask sides.

**Concepts:**
- `map[int64]*priceLevel` = hash map from price to level
- `[]int64` = sorted price array
- `sync.RWMutex` = read-write lock for thread safety

**Your task:** Add this:

```go
type OrderBook struct {
	symbol string

	mu sync.RWMutex

	bids map[int64]*priceLevel
	asks map[int64]*priceLevel

	bidPrices []int64
	askPrices []int64

	tradeSeq int64
}
```

**What this does:**
- `symbol` = trading pair (e.g., "BTC-USD")
- `mu` = protects concurrent access
- `bids` = buy orders (map: price → level)
- `asks` = sell orders (map: price → level)
- `bidPrices` = sorted bid prices (highest first)
- `askPrices` = sorted ask prices (lowest first)
- `tradeSeq` = counter for trade IDs

---

## Step 4: Constructor Function

**What you're building:** Create new empty order book.

**Your task:** Add this:

```go
func NewOrderBook(symbol string) *OrderBook {
	return &OrderBook{
		symbol: symbol,
		bids:   make(map[int64]*priceLevel),
		asks:   make(map[int64]*priceLevel),
	}
}
```

**What this does:**
- Creates order book for given symbol
- Initializes empty bid/ask maps
- `make(map[...])` = create empty map

---

## Step 5: Simple Accessor Methods

**What you're building:** Read-only methods to query book state.

**Concepts:**
- `(ob *OrderBook)` = method receiver
- `RLock/RUnlock` = read lock (multiple readers allowed)

**Your task:** Add these three methods:

```go
func (ob *OrderBook) Symbol() string {
	return ob.symbol
}

func (ob *OrderBook) BidLevels() int {
	ob.mu.RLock()
	defer ob.mu.RUnlock()
	return len(ob.bidPrices)
}

func (ob *OrderBook) AskLevels() int {
	ob.mu.RLock()
	defer ob.mu.RUnlock()
	return len(ob.askPrices)
}
```

**What this does:**
- `Symbol()` = return symbol name
- `BidLevels()` = count of bid price levels
- `AskLevels()` = count of ask price levels
- `defer` = runs at end of function (auto-unlock)

---

## Step 6: Add Limit Order (HIGH LEVEL)

**What you're building:** Public method to submit limit order.

**Concepts:**
- Validates order
- Matches first, then rests remainder

**Your task:** Add this:

```go
func (ob *OrderBook) AddLimitOrder(order Order) []Trade {
	if order.Qty <= 0 {
		return nil
	}
	if order.PriceTicks <= 0 {
		return nil
	}

	ob.mu.Lock()
	defer ob.mu.Unlock()

	trades := ob.match(&order)
	if order.Qty > 0 {
		ob.addResting(order)
	}
	return trades
}
```

**What this does:**
- Validates quantity and price
- Locks book for writing
- Tries to match against opposite side
- If quantity remains, adds to resting orders
- Returns list of trades

---

## Step 7: Add Market Order (HIGH LEVEL)

**What you're building:** Public method to submit market order.

**Your task:** Add this:

```go
func (ob *OrderBook) AddMarketOrder(order Order) []Trade {
	if order.Qty <= 0 {
		return nil
	}

	ob.mu.Lock()
	defer ob.mu.Unlock()

	return ob.match(&order)
}
```

**What this does:**
- Validates quantity
- Matches immediately
- Never rests remainder (market orders execute or die)

---

## Step 8: Match Logic - Buy Side (COMPLEX!)

**What you're building:** Core matching algorithm for buy orders.

**This is the hardest part. Read carefully!**

**Your task:** Add this method:

```go
func (ob *OrderBook) match(taker *Order) []Trade {
	trades := make([]Trade, 0, 8)
	if taker.Side == Buy {
		for taker.Qty > 0 && len(ob.askPrices) > 0 {
			bestAsk := ob.askPrices[0]
			if taker.PriceTicks > 0 && taker.PriceTicks < bestAsk {
				break
			}
			level := ob.asks[bestAsk]
			for taker.Qty > 0 && len(level.orders) > 0 {
				maker := &level.orders[0]
				qty := min64(taker.Qty, maker.Qty)
				taker.Qty -= qty
				maker.Qty -= qty
				trades = append(trades, ob.newTrade(bestAsk, qty, maker.ID, taker.ID))
				if maker.Qty == 0 {
					level.orders = level.orders[1:]
				}
			}
			if len(level.orders) == 0 {
				delete(ob.asks, bestAsk)
				ob.askPrices = ob.askPrices[1:]
			}
		}
		return trades
	}

	// Sell side (next part)
```

**What this does (Buy side):**
- Loop while taker has qty and asks exist
- Get best (lowest) ask price
- If limit order and price too high, stop
- Get the price level
- Match FIFO against orders at that level
- Calculate fill qty (min of taker and maker)
- Reduce both quantities
- Create trade
- Remove fully filled maker orders
- Remove empty price levels
- Continue to next level if needed

---

## Step 9: Match Logic - Sell Side

**What you're building:** Mirror logic for sell orders.

**Your task:** Replace the `// Sell side (next part)` comment with this:

```go
	for taker.Qty > 0 && len(ob.bidPrices) > 0 {
		bestBid := ob.bidPrices[0]
		if taker.PriceTicks > 0 && taker.PriceTicks > bestBid {
			break
		}
		level := ob.bids[bestBid]
		for taker.Qty > 0 && len(level.orders) > 0 {
			maker := &level.orders[0]
			qty := min64(taker.Qty, maker.Qty)
			taker.Qty -= qty
			maker.Qty -= qty
			trades = append(trades, ob.newTrade(bestBid, qty, maker.ID, taker.ID))
			if maker.Qty == 0 {
				level.orders = level.orders[1:]
			}
		}
		if len(level.orders) == 0 {
			delete(ob.bids, bestBid)
			ob.bidPrices = ob.bidPrices[1:]
		}
	}
	return trades
}
```

**What this does (Sell side):**
- Same as buy side but opposite
- Matches against bids (highest first)
- If limit order and bid too low, stop

---

## Step 10: Add Resting Order

**What you're building:** Store unfilled limit order in book.

**Concepts:**
- Bids sorted descending (highest first)
- Asks sorted ascending (lowest first)

**Your task:** Add this:

```go
func (ob *OrderBook) addResting(order Order) {
	if order.Side == Buy {
		level, ok := ob.bids[order.PriceTicks]
		if !ok {
			level = &priceLevel{price: order.PriceTicks}
			ob.bids[order.PriceTicks] = level
			ob.bidPrices = append(ob.bidPrices, order.PriceTicks)
			sort.Slice(ob.bidPrices, func(i, j int) bool { return ob.bidPrices[i] > ob.bidPrices[j] })
		}
		level.orders = append(level.orders, order)
		return
	}

	level, ok := ob.asks[order.PriceTicks]
	if !ok {
		level = &priceLevel{price: order.PriceTicks}
		ob.asks[order.PriceTicks] = level
		ob.askPrices = append(ob.askPrices, order.PriceTicks)
		sort.Slice(ob.askPrices, func(i, j int) bool { return ob.askPrices[i] < ob.askPrices[j] })
	}
	level.orders = append(level.orders, order)
}
```

**What this does:**
- For buy: add to bids, sort descending
- For sell: add to asks, sort ascending
- If price level doesn't exist, create it
- Append order to level's queue

---

## Step 11: Create Trade

**What you're building:** Generate trade object with unique ID.

**Your task:** Add this:

```go
func (ob *OrderBook) newTrade(priceTicks int64, qty int64, makerOrderID, takerOrderID string) Trade {
	ob.tradeSeq++
	return Trade{
		ID:           fmt.Sprintf("t%d", ob.tradeSeq),
		PriceTicks:   priceTicks,
		Qty:          qty,
		MakerOrderID: makerOrderID,
		TakerOrderID: takerOrderID,
		TsNano:       time.Now().UnixNano(),
	}
}
```

**What this does:**
- Increments trade counter
- Creates trade with sequential ID
- Records maker/taker order IDs
- Timestamps the trade

---

## Step 12: Helper Function

**What you're building:** Utility to find minimum of two numbers.

**Your task:** Add this:

```go
func min64(a, b int64) int64 {
	if a < b {
		return a
	}
	return b
}
```

**What this does:**
- Returns smaller of two int64 values
- Used to calculate fill quantity

---

## Now Type It!

1. Open `internal/engine/orderbook.go`
2. Start with Step 1 and build incrementally
3. Take your time with Steps 8-9 (matching logic)
4. After you finish, let me know and we'll test it

**This is the heart of the exchange. Understanding this = understanding trading systems!**
