import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    mixed_workload: {
      executor: 'ramping-vus',
      startVUs: 10,
      stages: [
        { duration: '30s', target: 50 },
        { duration: '1m', target: 100 },
        { duration: '1m', target: 100 },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<500'],
    'http_req_duration{name:order}': ['p(95)<10'],
    'http_req_duration{name:health}': ['p(95)<5'],
    'http_req_duration{name:book}': ['p(95)<10'],
    'http_req_duration{name:stats}': ['p(95)<10'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081';
let orderCounter = 0;

export default function () {
  // 1. Health check (20% of requests)
  if (Math.random() < 0.2) {
    const res = http.get(`${BASE_URL}/health`, { tags: { name: 'health' } });
    check(res, { 'health OK': (r) => r.status === 200 });
  }

  // 2. Submit order (50% of requests) - alternating buy/sell for matches
  if (Math.random() < 0.5) {
    orderCounter++;
    const isBuy = orderCounter % 3 !== 0; // 2/3 buys, 1/3 sells
    const isMarket = Math.random() < 0.15; // 15% market orders

    let payload;
    if (isMarket) {
      payload = JSON.stringify({
        order_id: `k6-mixed-${__VU}-${orderCounter}-${Date.now()}`,
        side: isBuy ? 'buy' : 'sell',
        order_type: 'market',
        qty: 5000000 + Math.floor(Math.random() * 5000000),
      });
    } else {
      // 50% chance of crossing price (matching), 50% resting
      const spreadBasis = Math.random() < 0.5 ? 0 : 10000;
      const price = isBuy
        ? 3000000 + spreadBasis   // buy at 30000.00 or 30100.00
        : 3000000 - spreadBasis;  // sell at 30000.00 or 29900.00

      payload = JSON.stringify({
        order_id: `k6-mixed-${__VU}-${orderCounter}-${Date.now()}`,
        side: isBuy ? 'buy' : 'sell',
        order_type: 'limit',
        price_ticks: price,
        qty: 1000000 + Math.floor(Math.random() * 9000000),
      });
    }

    const res = http.post(`${BASE_URL}/orders`, payload, {
      headers: { 'Content-Type': 'application/json' },
      tags: { name: 'order' },
    });
    check(res, {
      'order accepted': (r) => r.status === 200,
    });
  }

  // 3. Get order book (15% of requests)
  if (Math.random() < 0.5) {
    const res = http.get(`${BASE_URL}/book`, { tags: { name: 'book' } });
    check(res, { 'book OK': (r) => r.status === 200 });
  }

  // 4. Get stats (15% of requests)
  if (Math.random() < 0.5) {
    const res = http.get(`${BASE_URL}/stats`, { tags: { name: 'stats' } });
    check(res, { 'stats OK': (r) => r.status === 200 });
  }

  sleep(0.1);
}
