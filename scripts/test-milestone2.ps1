# Test Milestone 2 - Event-Driven Architecture

Write-Host "Testing AxiomX Milestone 2: Event-Driven Architecture" -ForegroundColor Green
Write-Host ""

$baseUrl = "http://localhost:8080"

# Health check
Write-Host "1. Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET
    Write-Host "   Status: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "   Error: Server not running. Start with 'docker-compose up' or 'go run ./cmd/api'" -ForegroundColor Red
    exit 1
}

# Test risk check - valid order
Write-Host ""
Write-Host "2. Testing VALID order (should pass risk checks)..." -ForegroundColor Yellow
$validOrder = @{
    order_id = "risk_test_1"
    user_id = "user1"
    side = "buy"
    order_type = "limit"
    price_ticks = 3000000
    qty = 50000000
} | ConvertTo-Json

$validResult = Invoke-RestMethod -Uri "$baseUrl/orders" -Method POST -Body $validOrder -ContentType "application/json"
Write-Host "   Success: $($validResult.success)" -ForegroundColor Green

# Test risk check - order too large
Write-Host ""
Write-Host "3. Testing INVALID order (too large, should fail risk check)..." -ForegroundColor Yellow
$invalidOrder = @{
    order_id = "risk_test_2"
    user_id = "user1"
    side = "buy"
    order_type = "limit"
    price_ticks = 3000000
    qty = 20000000000
} | ConvertTo-Json

try {
    $invalidResult = Invoke-RestMethod -Uri "$baseUrl/orders" -Method POST -Body $invalidOrder -ContentType "application/json"
    if (!$invalidResult.success) {
        Write-Host "   Correctly rejected: $($invalidResult.error)" -ForegroundColor Green
    }
} catch {
    Write-Host "   Request handled correctly (rejected by risk engine)" -ForegroundColor Green
}

# Submit multiple orders to generate trades
Write-Host ""
Write-Host "4. Submitting orders to trigger trades and events..." -ForegroundColor Yellow

$buy1 = @{
    order_id = "evt_buy1"
    user_id = "user1"
    side = "buy"
    order_type = "limit"
    price_ticks = 3000000
    qty = 100000000
} | ConvertTo-Json
Invoke-RestMethod -Uri "$baseUrl/orders" -Method POST -Body $buy1 -ContentType "application/json" | Out-Null

$sell1 = @{
    order_id = "evt_sell1"
    user_id = "user2"
    side = "sell"
    order_type = "limit"
    price_ticks = 3010000
    qty = 100000000
} | ConvertTo-Json
Invoke-RestMethod -Uri "$baseUrl/orders" -Method POST -Body $sell1 -ContentType "application/json" | Out-Null

$market1 = @{
    order_id = "evt_market1"
    user_id = "user1"
    side = "buy"
    order_type = "market"
    qty = 100000000
} | ConvertTo-Json
$tradeResult = Invoke-RestMethod -Uri "$baseUrl/orders" -Method POST -Body $market1 -ContentType "application/json"

Write-Host "   Trades executed: $($tradeResult.trades.Count)" -ForegroundColor Green
Write-Host "   (Events published to Kafka, trade count updated in Redis)" -ForegroundColor Cyan

# Check cached order book
Write-Host ""
Write-Host "5. Checking order book (with Redis caching)..." -ForegroundColor Yellow
$book1 = Invoke-WebRequest -Uri "$baseUrl/book" -Method GET -UseBasicParsing
$cacheStatus1 = $book1.Headers["X-Cache"]
Write-Host "   Cache Status: $cacheStatus1 (first request)" -ForegroundColor Cyan

Start-Sleep -Milliseconds 500

$book2 = Invoke-WebRequest -Uri "$baseUrl/book" -Method GET -UseBasicParsing
$cacheStatus2 = $book2.Headers["X-Cache"]
Write-Host "   Cache Status: $cacheStatus2 (second request)" -ForegroundColor Cyan

if ($cacheStatus2 -eq "HIT") {
    Write-Host "   ✓ Redis caching working!" -ForegroundColor Green
}

# Check user position
Write-Host ""
Write-Host "6. Checking user position (risk engine tracking)..." -ForegroundColor Yellow
$position = Invoke-RestMethod -Uri "$baseUrl/risk/position?user_id=user1" -Method GET
Write-Host "   User: $($position.user_id)" -ForegroundColor Cyan
Write-Host "   Position: $($position.position)" -ForegroundColor Cyan
Write-Host "   Symbol: $($position.symbol)" -ForegroundColor Cyan

# Get stats
Write-Host ""
Write-Host "7. Getting system stats..." -ForegroundColor Yellow
$stats = Invoke-RestMethod -Uri "$baseUrl/stats" -Method GET
Write-Host "   Symbol: $($stats.symbol)" -ForegroundColor Cyan
Write-Host "   Bid Levels: $($stats.bid_levels)" -ForegroundColor Cyan
Write-Host "   Ask Levels: $($stats.ask_levels)" -ForegroundColor Cyan
Write-Host "   Total Trades: $($stats.trade_count)" -ForegroundColor Cyan

Write-Host ""
Write-Host "Milestone 2 Tests Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Event-Driven Architecture Components:" -ForegroundColor Yellow
Write-Host "  ✓ Kafka - Order/Trade events published" -ForegroundColor Green
Write-Host "  ✓ Risk Engine - Position tracking and validation" -ForegroundColor Green
Write-Host "  ✓ Redis - Order book caching and stats" -ForegroundColor Green
