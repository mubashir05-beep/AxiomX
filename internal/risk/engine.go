package risk

import (
	"fmt"
	"sync"
)

type CheckResult struct {
	Approved bool
	Reason   string
}

type Position struct {
	Symbol string
	Qty    int64 // Positive for long, negative for short
}

type RiskEngine struct {
	mu              sync.RWMutex
	positions       map[string]*Position // userID -> Position
	maxPositionSize int64
	maxOrderSize    int64
}

func NewRiskEngine() *RiskEngine {
	return &RiskEngine{
		positions:       make(map[string]*Position),
		maxPositionSize: 1000_0000_0000, // 1000 BTC max position
		maxOrderSize:    100_0000_0000,  // 100 BTC max single order
	}
}

func (re *RiskEngine) ValidateOrder(userID string, side string, qty int64, priceTicks int64) CheckResult {
	re.mu.RLock()
	defer re.mu.RUnlock()

	// Check 1: Order size limit
	if qty > re.maxOrderSize {
		return CheckResult{
			Approved: false,
			Reason:   fmt.Sprintf("Order size %d exceeds max %d", qty, re.maxOrderSize),
		}
	}

	// Check 2: Minimum order size
	if qty <= 0 {
		return CheckResult{
			Approved: false,
			Reason:   "Order quantity must be positive",
		}
	}

	// Check 3: Price sanity (for limit orders)
	if priceTicks > 0 {
		if priceTicks < 1000_00 { // Min $1000
			return CheckResult{
				Approved: false,
				Reason:   "Price too low",
			}
		}
		if priceTicks > 10000000_00 { // Max $10M
			return CheckResult{
				Approved: false,
				Reason:   "Price too high",
			}
		}
	}

	// Check 4: Position limit
	currentPos := re.positions[userID]
	if currentPos != nil {
		var newQty int64
		if side == "buy" {
			newQty = currentPos.Qty + qty
		} else {
			newQty = currentPos.Qty - qty
		}

		if abs(newQty) > re.maxPositionSize {
			return CheckResult{
				Approved: false,
				Reason:   fmt.Sprintf("Would exceed max position size %d", re.maxPositionSize),
			}
		}
	}

	return CheckResult{Approved: true}
}

func (re *RiskEngine) UpdatePosition(userID string, side string, qty int64) {
	re.mu.Lock()
	defer re.mu.Unlock()

	pos := re.positions[userID]
	if pos == nil {
		pos = &Position{Symbol: "BTC-USD", Qty: 0}
		re.positions[userID] = pos
	}

	if side == "buy" {
		pos.Qty += qty
	} else {
		pos.Qty -= qty
	}
}

func (re *RiskEngine) GetPosition(userID string) *Position {
	re.mu.RLock()
	defer re.mu.RUnlock()
	return re.positions[userID]
}

func abs(x int64) int64 {
	if x < 0 {
		return -x
	}
	return x
}
