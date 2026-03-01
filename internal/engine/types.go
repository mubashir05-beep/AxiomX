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
