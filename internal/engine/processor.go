package engine

import (
	"errors"
)

type OrderType uint8

const (
	Limit OrderType = iota
	Market
)

type SubmitResult struct {
	Trades []Trade
	Err    error
}

type orderRequest struct {
	order     Order
	orderType OrderType
	resultCh  chan SubmitResult
}

type MatchingProcessor struct {
	book   *OrderBook
	reqCh  chan orderRequest
	stopCh chan struct{}
}

func NewMatchingProcessor(symbol string, queSize int) *MatchingProcessor {
	if queSize <= 0 {
		queSize = 1024
	}
	processor := &MatchingProcessor{
		book:   NewOrderBook(symbol),
		reqCh:  make(chan orderRequest, queSize),
		stopCh: make(chan struct{}),
	}
	go processor.run()

	return processor
}

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

func (mp *MatchingProcessor) Submit(order Order, orderType OrderType) SubmitResult {
	resultCh := make(chan SubmitResult, 1)
	mp.reqCh <- orderRequest{order: order, orderType: orderType, resultCh: resultCh}
	return <-resultCh
}

func (mp *MatchingProcessor) Snapshot() (symbol string, bidLevels int, askLevels int) {
	return mp.book.Symbol(), mp.book.BidLevels(), mp.book.AskLevels()
}

func (mp *MatchingProcessor) Stop() {
	close(mp.stopCh)
}
