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
