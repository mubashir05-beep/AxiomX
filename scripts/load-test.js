import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    steady_load: {
      executor: 'ramping-vus',
      startVUs: 5,
      stages: [
        { duration: '20s', target: 20 },
        { duration: '40s', target: 20 },
        { duration: '20s', target: 0 },
      ],
      gracefulRampDown: '5s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<500'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081';

export default function () {
  const healthRes = http.get(`${BASE_URL}/health`);
  check(healthRes, {
    'health status is 200': (response) => response.status === 200,
  });

  const isBuy = Math.random() < 0.5;
  const orderPayload = JSON.stringify({
    order_id: `k6-${__VU}-${__ITER}-${Date.now()}`,
    side: isBuy ? 'buy' : 'sell',
    order_type: 'limit',
    price_ticks: isBuy ? 3000000 : 3010000,
    qty: 1000000,
  });

  const orderRes = http.post(`${BASE_URL}/orders`, orderPayload, {
    headers: { 'Content-Type': 'application/json' },
  });
  check(orderRes, {
    'order status is 200/201': (response) => response.status === 200 || response.status === 201,
  });

  sleep(0.2);
}
