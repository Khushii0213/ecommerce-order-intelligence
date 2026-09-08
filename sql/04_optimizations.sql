-- Indexes support the selective filters and large joins in the revised queries.
CREATE INDEX IF NOT EXISTS idx_orders_status_purchase ON orders (order_status, order_purchase_ts);
CREATE INDEX IF NOT EXISTS idx_order_items_order_seller_product ON order_items (order_id, seller_id, product_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_status ON orders (customer_id, order_status);

-- Seller KPIs are read frequently by the dashboard but source facts update less often.
-- In a production system, refresh this on a scheduled cadence or use an incremental table.
CREATE MATERIALIZED VIEW seller_daily_kpis AS
SELECT DATE_TRUNC('day', o.order_purchase_ts)::DATE AS order_date,
       oi.seller_id,
       p.category,
       COUNT(*) AS item_count,
       COUNT(DISTINCT o.order_id) AS order_count,
       SUM(oi.item_price * oi.quantity) AS gmv,
       SUM((o.delivered_ts > o.estimated_delivery_ts)::INT) AS late_order_items
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY 1, 2, 3;

CREATE UNIQUE INDEX idx_seller_daily_kpis_unique ON seller_daily_kpis (order_date, seller_id, category);
CREATE INDEX idx_seller_daily_kpis_date ON seller_daily_kpis (order_date);
ANALYZE;
