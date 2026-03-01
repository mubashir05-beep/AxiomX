package engine

import (
	"fmt"
	"sort"
	"sync"
	"time"
)

type priceLevel struct {
	price  int64
	orders []Order
}

type OrderBook struct {
	symbol string

	mu sync.RWMutex

	bids map[int64]*priceLevel
	asks map[int64]*priceLevel

	bidPrices []int64
	askPrices []int64

	tradeSeq int64
}

func NewOrderBook(symbol string) *OrderBook {
	return &OrderBook{
		symbol: symbol,
		bids:   make(map[int64]*priceLevel),
		asks:   make(map[int64]*priceLevel),
	}
}

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

func (ob *OrderBook) AddMarketOrder(order Order) []Trade {
	if order.Qty <= 0 {
		return nil
	}

	ob.mu.Lock()
	defer ob.mu.Unlock()

	return ob.match(&order)
}

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

func min64(a, b int64) int64 {
	if a < b {
		return a
	}
	return b
}
