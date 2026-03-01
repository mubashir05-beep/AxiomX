package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

type BookSnapshot struct {
	Symbol    string `json:"symbol"`
	BidLevels int    `json:"bid_levels"`
	AskLevels int    `json:"ask_levels"`
	Timestamp int64  `json:"timestamp"`
}

type Cache struct {
	client *redis.Client
	active bool
	ctx    context.Context
}

func NewCache() *Cache {
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		fmt.Println("REDIS_ADDR not set, caching disabled")
		return &Cache{active: false, ctx: context.Background()}
	}

	client := redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: "",
		DB:       0,
	})

	ctx := context.Background()
	if err := client.Ping(ctx).Err(); err != nil {
		fmt.Printf("Redis connection failed: %v, caching disabled\n", err)
		return &Cache{active: false, ctx: ctx}
	}

	fmt.Printf("Redis cache initialized: %s\n", redisAddr)
	return &Cache{client: client, active: true, ctx: ctx}
}

func (c *Cache) SetBookSnapshot(snapshot BookSnapshot) error {
	if !c.active {
		return nil
	}

	data, err := json.Marshal(snapshot)
	if err != nil {
		return err
	}

	key := fmt.Sprintf("book:%s", snapshot.Symbol)
	return c.client.Set(c.ctx, key, data, 10*time.Second).Err()
}

func (c *Cache) GetBookSnapshot(symbol string) (*BookSnapshot, error) {
	if !c.active {
		return nil, fmt.Errorf("cache not active")
	}

	key := fmt.Sprintf("book:%s", symbol)
	data, err := c.client.Get(c.ctx, key).Result()
	if err != nil {
		return nil, err
	}

	var snapshot BookSnapshot
	if err := json.Unmarshal([]byte(data), &snapshot); err != nil {
		return nil, err
	}

	return &snapshot, nil
}

func (c *Cache) IncrementTradeCount() error {
	if !c.active {
		return nil
	}
	return c.client.Incr(c.ctx, "stats:trades").Err()
}

func (c *Cache) GetTradeCount() (int64, error) {
	if !c.active {
		return 0, fmt.Errorf("cache not active")
	}
	return c.client.Get(c.ctx, "stats:trades").Int64()
}

func (c *Cache) Close() error {
	if c.client != nil {
		return c.client.Close()
	}
	return nil
}
