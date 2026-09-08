\if :{?customers}
\else
  \set customers 10000
\endif
\if :{?sellers}
\else
  \set sellers 250
\endif
\if :{?products}
\else
  \set products 2000
\endif
\if :{?orders}
\else
  \set orders 50000
\endif

-- Fixed seed makes the portfolio dataset repeatable.
SELECT setseed(0.2026);

INSERT INTO customers (customer_id, customer_state, signup_date, acquisition_channel)
SELECT i,
       (ARRAY['DL','MH','KA','TN','UP','HR','RJ','WB'])[1 + floor(random() * 8)],
       DATE '2023-01-01' + floor(random() * 1095)::INT,
       (ARRAY['organic','paid_search','referral','social','marketplace'])[1 + floor(random() * 5)]
FROM generate_series(1, :customers) AS i;

INSERT INTO sellers (seller_id, seller_state, seller_segment)
SELECT i,
       (ARRAY['DL','MH','KA','TN','UP','HR','RJ','WB'])[1 + floor(random() * 8)],
       (ARRAY['long_tail','growth','managed','enterprise'])[1 + floor(random() * 4)]
FROM generate_series(1, :sellers) AS i;

INSERT INTO products (product_id, category, unit_cost, weight_g)
SELECT i,
       (ARRAY['electronics','home','beauty','fashion','sports','books','grocery','toys'])[1 + floor(random() * 8)],
       round((5 + random() * 500)::numeric, 2),
       100 + floor(random() * 4900)::INT
FROM generate_series(1, :products) AS i;

INSERT INTO orders (order_id, customer_id, order_status, order_purchase_ts, estimated_delivery_ts, delivered_ts, freight_value)
SELECT i, customer_id, status, purchase_ts, estimated_delivery_ts,
       CASE WHEN status = 'delivered' THEN estimated_delivery_ts +
         CASE WHEN random() < 0.20 THEN (1 + floor(random() * 4)) * INTERVAL '1 day'
              ELSE -floor(random() * 3) * INTERVAL '1 day' END
       END,
       round((20 + random() * 180)::numeric, 2)
FROM (
  SELECT order_seed.*,
         purchase_ts + (4 + floor(random() * 7)) * INTERVAL '1 day' AS estimated_delivery_ts
  FROM (
    SELECT i,
         1 + floor(random() * :customers)::BIGINT AS customer_id,
         TIMESTAMPTZ '2024-01-01 00:00:00+00' + floor(random() * 730) * INTERVAL '1 day' + floor(random() * 86400) * INTERVAL '1 second' AS purchase_ts,
         CASE WHEN random() < 0.08 THEN 'cancelled' WHEN random() < 0.04 THEN 'shipped' ELSE 'delivered' END AS status
    FROM generate_series(1, :orders) AS i
  ) AS order_seed
) generated;

-- One to three items per order, enough row growth to expose join and aggregation costs.
INSERT INTO order_items (order_id, item_no, product_id, seller_id, quantity, item_price)
SELECT o.order_id, item_no,
       1 + floor(random() * :products)::BIGINT,
       1 + floor(random() * :sellers)::BIGINT,
       1 + floor(random() * 3)::SMALLINT,
       round((10 + random() * 1200)::numeric, 2)
FROM orders o
CROSS JOIN LATERAL generate_series(1, 1 + (o.order_id % 3)::INT) AS item_series(item_no);

INSERT INTO payments (order_id, payment_method, payment_status, payment_value)
SELECT o.order_id,
       (ARRAY['upi','card','net_banking','wallet','cod'])[1 + floor(random() * 5)],
       CASE WHEN o.order_status = 'cancelled' AND random() < 0.35 THEN 'refunded'
            WHEN random() < 0.03 THEN 'failed' ELSE 'approved' END,
       round((o.freight_value + 20 + random() * 1600)::numeric, 2)
FROM orders o;

INSERT INTO reviews (order_id, review_score, review_ts)
SELECT order_id,
       CASE WHEN delivered_ts > estimated_delivery_ts THEN 1 + floor(random() * 3)::SMALLINT
            ELSE 3 + floor(random() * 3)::SMALLINT END,
       COALESCE(delivered_ts, order_purchase_ts) + INTERVAL '2 days'
FROM orders
WHERE order_status = 'delivered' AND random() < 0.72;

ANALYZE;
