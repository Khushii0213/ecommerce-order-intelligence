DROP MATERIALIZED VIEW IF EXISTS seller_daily_kpis;
DROP TABLE IF EXISTS payments, reviews, order_items, orders, products, sellers, customers CASCADE;

CREATE TABLE customers (
  customer_id BIGINT PRIMARY KEY,
  customer_state CHAR(2) NOT NULL,
  signup_date DATE NOT NULL,
  acquisition_channel TEXT NOT NULL
);

CREATE TABLE sellers (
  seller_id BIGINT PRIMARY KEY,
  seller_state CHAR(2) NOT NULL,
  seller_segment TEXT NOT NULL
);

CREATE TABLE products (
  product_id BIGINT PRIMARY KEY,
  category TEXT NOT NULL,
  unit_cost NUMERIC(10,2) NOT NULL,
  weight_g INTEGER NOT NULL
);

CREATE TABLE orders (
  order_id BIGINT PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
  order_status TEXT NOT NULL CHECK (order_status IN ('delivered', 'cancelled', 'shipped')),
  order_purchase_ts TIMESTAMPTZ NOT NULL,
  estimated_delivery_ts TIMESTAMPTZ NOT NULL,
  delivered_ts TIMESTAMPTZ,
  freight_value NUMERIC(10,2) NOT NULL,
  CHECK ((order_status = 'delivered' AND delivered_ts IS NOT NULL) OR order_status <> 'delivered')
);

CREATE TABLE order_items (
  order_id BIGINT NOT NULL REFERENCES orders(order_id),
  item_no SMALLINT NOT NULL,
  product_id BIGINT NOT NULL REFERENCES products(product_id),
  seller_id BIGINT NOT NULL REFERENCES sellers(seller_id),
  quantity SMALLINT NOT NULL CHECK (quantity > 0),
  item_price NUMERIC(10,2) NOT NULL,
  PRIMARY KEY (order_id, item_no)
);

CREATE TABLE payments (
  payment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(order_id),
  payment_method TEXT NOT NULL,
  payment_status TEXT NOT NULL CHECK (payment_status IN ('approved', 'failed', 'refunded')),
  payment_value NUMERIC(10,2) NOT NULL
);

CREATE TABLE reviews (
  order_id BIGINT PRIMARY KEY REFERENCES orders(order_id),
  review_score SMALLINT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
  review_ts TIMESTAMPTZ NOT NULL
);
