# Step-by-Step Learning Path

All code has been cleared. Now you'll rebuild everything yourself to truly understand it!

---

## Learning Order (Follow This!)

### 1. **TYPES_GUIDE.md** (EASIEST - Start here!)
- File: `internal/engine/types.go`
- Time: ~10 minutes
- What: Basic data structures (Order, Trade, Side)
- Why first: Foundation for everything else

### 2. **PROCESSOR_GUIDE.md** (Goroutines & Channels)
- File: `internal/engine/processor.go`
- Time: ~30 minutes
- What: Worker goroutine that processes orders
- Why second: Learn Go concurrency patterns

### 3. **ORDERBOOK_GUIDE.md** (HARDEST - Core logic!)
- File: `internal/engine/orderbook.go`
- Time: ~45 minutes
- What: Matching engine algorithm
- Why third: The heart of the exchange

### 4. **MAIN_GUIDE.md** (EASIEST - Tie it together!)
- File: `cmd/engine/main.go`
- Time: ~10 minutes
- What: Demo that runs everything
- Why last: See your engine in action!

---

## How to Use Each Guide

1. **Open the guide** (e.g., TYPES_GUIDE.md)
2. **Open the target file** (e.g., internal/engine/types.go)
3. **Read each step carefully**
4. **Type the code yourself** (don't copy-paste!)
5. **Save frequently**
6. **Tell me when you finish each step** and I'll verify it
7. **Move to next step**

---

## After Each File

When you complete a file:
1. Tell me "finished [filename]"
2. I'll verify it compiles
3. We'll test if needed
4. Move to next guide

---

## Final Test

After completing all 4 files, run:

```powershell
go run ./cmd/engine
```

You should see:
```
symbol=BTC-USD bids=1 asks=0 trades=1
trade id=t1 price=3010000 qty=100000000 maker=o2 taker=o3
```

---

## Why This Approach?

- **Typing yourself = muscle memory**
- **Step-by-step = no overwhelm**
- **Explanations = understanding, not just copying**
- **I verify = catch mistakes early**

---

## Start Now!

**Open TYPES_GUIDE.md and begin with Step 1!**

When ready, tell me: "starting types.go" or "done with step X"
