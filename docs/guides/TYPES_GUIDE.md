# Building Types - Step by Step

This is the EASIEST file to start with! You'll define the basic data types for orders and trades.

---

## Step 1: Define Side (Buy vs Sell)

**What you're building:** A type to represent whether an order is a buy or sell.

**Concepts:**
- `type X uint8` = creates a small integer type (takes only 1 byte)
- `const ( ... )` = defines constants
- `iota` = auto-counter (starts at 0, then 1, 2...)

**Your task:** In `types.go`, add this after `package engine`:

```go
type Side uint8

const (
	Buy Side = iota  // 0
	Sell             // 1
)
```

**What this does:**
- `Buy` = 0
- `Sell` = 1
- Very memory-efficient (1 byte instead of string)

---

## Step 2: Define Order Structure

**What you're building:** The main order data structure.

**Concepts:**
- `struct { ... }` = data container with named fields
- `int64` = 64-bit integer (can hold large numbers)
- `string` = text

**Your task:** Add this:

```go
type Order struct {
	ID         string
	Side       Side
	PriceTicks int64
	Qty        int64
	TsNano     int64
}
```

**What this does:**
- `ID` = unique order identifier (like "o1", "o2")
- `Side` = Buy or Sell
- `PriceTicks` = price in "ticks" (e.g., 30000_00 = $30000.00, using 2 decimal places)
- `Qty` = quantity in smallest units (e.g., 1_0000_0000 = 1.0 BTC with 8 decimals)
- `TsNano` = timestamp in nanoseconds

**Why ticks?** Faster integer math, no floating-point errors!

---

## Step 3: Helper Function to Create Orders

**What you're building:** A factory function to easily create orders.

**Concepts:**
- `func NewX(...) X` = constructor pattern
- Returns a new `Order` with all fields filled

**Your task:** Add this:

```go
func NewOrder(id string, side Side, priceTicks int64, qty int64, tsNano int64) Order {
	return Order{ID: id, Side: side, PriceTicks: priceTicks, Qty: qty, TsNano: tsNano}
}
```

**What this does:**
- Makes it easy to create orders: `NewOrder("o1", Buy, 30000, 1000, time.Now().UnixNano())`
- All parameters in one line

---

## Step 4: Define Trade Structure

**What you're building:** Result of matching two orders.

**Your task:** Add this:

```go
type Trade struct {
	ID           string
	PriceTicks   int64
	Qty          int64
	MakerOrderID string
	TakerOrderID string
	TsNano       int64
}
```

**What this does:**
- `ID` = trade identifier (like "t1", "t2")
- `PriceTicks` = execution price
- `Qty` = filled quantity
- `MakerOrderID` = order that was resting in book
- `TakerOrderID` = order that triggered the trade
- `TsNano` = trade timestamp

---

## Complete Example

After typing all steps, your `types.go` should look like:

```go
package engine

type Side uint8

const (
	Buy Side = iota
	Sell
)

type Order struct {
	ID         string
	Side       Side
	PriceTicks int64
	Qty        int64
	TsNano     int64
}

func NewOrder(id string, side Side, priceTicks int64, qty int64, tsNano int64) Order {
	return Order{ID: id, Side: side, PriceTicks: priceTicks, Qty: qty, TsNano: tsNano}
}

type Trade struct {
	ID           string
	PriceTicks   int64
	Qty          int64
	MakerOrderID string
	TakerOrderID string
	TsNano       int64
}
```

---

## Now Type It!

1. Open `internal/engine/types.go`
2. Start with Step 1 and type it yourself
3. After each step, save and let me know
4. When done, we'll verify it compiles

**This is the foundation for everything else. Start now!**
