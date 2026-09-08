-- Optimized A: range predicate is sargable; the materialized view avoids rejoining
-- high-volume fact tables for a seller-health dashboard.
EXPLAIN (ANALYZE, BUFFERS)
SELECT seller_id, category,
       SUM(item_count) AS items_sold,
       ROUND(100.0 * SUM(late_order_items) / NULLIF(SUM(item_count), 0), 2) AS late_delivery_pct,
       ROUND(SUM(gmv), 2) AS gmv
FROM seller_daily_kpis
WHERE order_date >= DATE '2025-01-01'
  AND order_date < DATE '2025-07-01'
GROUP BY seller_id, category
HAVING SUM(item_count) >= 5
ORDER BY late_delivery_pct DESC, gmv DESC
LIMIT 25;

-- Optimized B: range predicate can use idx_orders_status_purchase. Freight is
-- allocated once per item to avoid multiplying an order-level measure.
EXPLAIN (ANALYZE, BUFFERS)
WITH cancelled_orders AS (
  SELECT order_id, customer_id, freight_value
  FROM orders
  WHERE order_status = 'cancelled'
    AND order_purchase_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
    AND order_purchase_ts < TIMESTAMPTZ '2025-07-01 00:00:00+00'
)
SELECT c.acquisition_channel, p.category,
       COUNT(DISTINCT co.order_id) AS cancelled_orders,
       ROUND(SUM(oi.item_price * oi.quantity + co.freight_value / item_counts.item_count), 2) AS revenue_at_risk
FROM cancelled_orders co
JOIN customers c ON c.customer_id = co.customer_id
JOIN order_items oi ON oi.order_id = co.order_id
JOIN LATERAL (
  SELECT COUNT(*) AS item_count
  FROM order_items oi_count
  WHERE oi_count.order_id = co.order_id
) AS item_counts ON TRUE
JOIN products p ON p.product_id = oi.product_id
GROUP BY c.acquisition_channel, p.category
ORDER BY revenue_at_risk DESC;
