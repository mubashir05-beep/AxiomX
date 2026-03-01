# Test the AxiomX API

Write-Host "Testing AxiomX Matching Engine API" -ForegroundColor Green
Write-Host ""

# Health check
Write-Host "1. Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    Write-Host "   Status: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "   Error: Server not running. Start with 'go run ./cmd/api'" -ForegroundColor Red
    exit 1
}

# Submit limit buy order
Write-Host ""
Write-Host "2. Submitting limit BUY order (price=$30,000, qty=2.0 BTC)..." -ForegroundColor Yellow
$buyOrder = @{
    order_id = "buy1"
    side = "buy"
    order_type = "limit"
    price_ticks = 3000000
    qty = 200000000
} | ConvertTo-Json

$buyResult = Invoke-RestMethod -Uri "http://localhost:8080/orders" -Method POST -Body $buyOrder -ContentType "application/json"
Write-Host "   Success: $($buyResult.success), Trades: $($buyResult.trades.Count)" -ForegroundColor Green

# Submit limit sell order
Write-Host ""
Write-Host "3. Submitting limit SELL order (price=$30,100, qty=1.0 BTC)..." -ForegroundColor Yellow
$sellOrder = @{
    order_id = "sell1"
    side = "sell"
    order_type = "limit"
    price_ticks = 3010000
    qty = 100000000
} | ConvertTo-Json

$sellResult = Invoke-RestMethod -Uri "http://localhost:8080/orders" -Method POST -Body $sellOrder -ContentType "application/json"
Write-Host "   Success: $($sellResult.success), Trades: $($sellResult.trades.Count)" -ForegroundColor Green

# Check order book
Write-Host ""
Write-Host "4. Checking order book..." -ForegroundColor Yellow
$book = Invoke-RestMethod -Uri "http://localhost:8080/book" -Method GET
Write-Host "   Symbol: $($book.symbol)" -ForegroundColor Green
Write-Host "   Bid Levels: $($book.bid_levels)" -ForegroundColor Green
Write-Host "   Ask Levels: $($book.ask_levels)" -ForegroundColor Green

# Submit market buy order that will match
Write-Host ""
Write-Host "5. Submitting market BUY order (qty=1.0 BTC) - should match sell1..." -ForegroundColor Yellow
$marketOrder = @{
    order_id = "market1"
    side = "buy"
    order_type = "market"
    qty = 100000000
} | ConvertTo-Json

$marketResult = Invoke-RestMethod -Uri "http://localhost:8080/orders" -Method POST -Body $marketOrder -ContentType "application/json"
Write-Host "   Success: $($marketResult.success), Trades: $($marketResult.trades.Count)" -ForegroundColor Green
if ($marketResult.trades.Count -gt 0) {
    $trade = $marketResult.trades[0]
    Write-Host "   Trade ID: $($trade.ID)" -ForegroundColor Cyan
    Write-Host "   Price: $($trade.PriceTicks)" -ForegroundColor Cyan
    Write-Host "   Qty: $($trade.Qty)" -ForegroundColor Cyan
    Write-Host "   Maker: $($trade.MakerOrderID) -> Taker: $($trade.TakerOrderID)" -ForegroundColor Cyan
}

# Final book state
Write-Host ""
Write-Host "6. Final order book state..." -ForegroundColor Yellow
$finalBook = Invoke-RestMethod -Uri "http://localhost:8080/book" -Method GET
Write-Host "   Bid Levels: $($finalBook.bid_levels)" -ForegroundColor Green
Write-Host "   Ask Levels: $($finalBook.ask_levels)" -ForegroundColor Green

Write-Host ""
Write-Host "All tests completed!" -ForegroundColor Green
