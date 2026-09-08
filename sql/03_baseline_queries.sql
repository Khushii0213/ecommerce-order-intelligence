-- Baseline A: delivery-delay analysis. DATE() on the timestamp prevents a normal
-- timestamp index from being used efficiently, and all joins happen before aggregation.
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.seller_id, p.category,
       COUNT(*) AS items_sold,
       ROUND(100.0 * AVG((o.delivered_ts > o.estimated_delivery_ts)::INT), 2) AS late_delivery_pct,
       ROUND(SUM(oi.item_price * oi.quantity), 2) AS gmv
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN sellers s ON s.seller_id = oi.seller_id
WHERE DATE(o.order_purchase_ts) BETWEEN DATE '2025-01-01' AND DATE '2025-06-30'
  AND o.order_status = 'delivered'
GROUP BY s.seller_id, p.category
HAVING COUNT(*) >= 5
ORDER BY late_delivery_pct DESC, gmv DESC
LIMIT 25;

-- Baseline B: cancellation leakage. This computes revenue at item grain and uses
-- a non-sargable date predicate, generating unnecessary work at scale.
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.acquisition_channel, p.category,
       COUNT(DISTINCT o.order_id) AS cancelled_orders,
       ROUND(SUM(oi.item_price * oi.quantity + o.freight_value), 2) AS revenue_at_risk
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE TO_CHAR(o.order_purchase_ts, 'YYYY-MM') BETWEEN '2025-01' AND '2025-06'
  AND o.order_status = 'cancelled'
GROUP BY c.acquisition_channel, p.category
ORDER BY revenue_at_risk DESC;
