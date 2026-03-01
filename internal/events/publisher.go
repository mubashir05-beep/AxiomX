package events

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"axiomx/internal/engine"

	"github.com/segmentio/kafka-go"
)

type EventType string

const (
	OrderSubmitted EventType = "ORDER_SUBMITTED"
	TradeExecuted  EventType = "TRADE_EXECUTED"
)

type Event struct {
	Type      EventType   `json:"type"`
	Timestamp int64       `json:"timestamp"`
	Data      interface{} `json:"data"`
}

type OrderEvent struct {
	OrderID    string `json:"order_id"`
	Side       string `json:"side"`
	OrderType  string `json:"order_type"`
	PriceTicks int64  `json:"price_ticks"`
	Qty        int64  `json:"qty"`
}

type TradeEvent struct {
	TradeID      string `json:"trade_id"`
	PriceTicks   int64  `json:"price_ticks"`
	Qty          int64  `json:"qty"`
	MakerOrderID string `json:"maker_order_id"`
	TakerOrderID string `json:"taker_order_id"`
	Timestamp    int64  `json:"timestamp"`
}

type Publisher struct {
	writer *kafka.Writer
	active bool
}

func NewPublisher() *Publisher {
	kafkaBroker := os.Getenv("KAFKA_BROKER")
	if kafkaBroker == "" {
		fmt.Println("KAFKA_BROKER not set, events will not be published")
		return &Publisher{active: false}
	}

	writer := &kafka.Writer{
		Addr:         kafka.TCP(kafkaBroker),
		Topic:        "trading-events",
		Balancer:     &kafka.LeastBytes{},
		RequiredAcks: kafka.RequireOne,
		Async:        true, // Non-blocking for performance
	}

	fmt.Printf("Kafka publisher initialized: %s\n", kafkaBroker)
	return &Publisher{writer: writer, active: true}
}

func (p *Publisher) PublishOrderSubmitted(orderID, side, orderType string, priceTicks, qty int64) error {
	if !p.active {
		return nil
	}

	event := Event{
		Type:      OrderSubmitted,
		Timestamp: time.Now().UnixNano(),
		Data: OrderEvent{
			OrderID:    orderID,
			Side:       side,
			OrderType:  orderType,
			PriceTicks: priceTicks,
			Qty:        qty,
		},
	}

	return p.publish(event)
}

func (p *Publisher) PublishTrade(trade engine.Trade) error {
	if !p.active {
		return nil
	}

	event := Event{
		Type:      TradeExecuted,
		Timestamp: time.Now().UnixNano(),
		Data: TradeEvent{
			TradeID:      trade.ID,
			PriceTicks:   trade.PriceTicks,
			Qty:          trade.Qty,
			MakerOrderID: trade.MakerOrderID,
			TakerOrderID: trade.TakerOrderID,
			Timestamp:    trade.TsNano,
		},
	}

	return p.publish(event)
}

func (p *Publisher) publish(event Event) error {
	data, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	msg := kafka.Message{
		Key:   []byte(fmt.Sprintf("%v", event.Type)),
		Value: data,
		Time:  time.Now(),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return p.writer.WriteMessages(ctx, msg)
}

func (p *Publisher) Close() error {
	if p.writer != nil {
		return p.writer.Close()
	}
	return nil
}
