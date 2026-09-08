import os

import pandas as pd
import psycopg
import streamlit as st


st.set_page_config(page_title="Order Intelligence", page_icon="📦", layout="wide")


def connection_url() -> str:
    if "DATABASE_URL" in st.secrets:
        return st.secrets["DATABASE_URL"]

    return os.getenv(
        "DATABASE_URL",
        "postgresql://analyst:analyst@localhost:5432/ecommerce",
    )


@st.cache_data(ttl=300, show_spinner=False)
def query(sql: str, params: tuple = ()) -> pd.DataFrame:
    with psycopg.connect(connection_url()) as conn:
        return pd.read_sql_query(sql, conn, params=params)


st.title("E-commerce Order Intelligence")
st.caption("Delivery reliability, cancellation leakage, and seller actions - powered by PostgreSQL.")

try:
    bounds = query("SELECT MIN(order_purchase_ts)::date AS min_date, MAX(order_purchase_ts)::date AS max_date FROM orders")
    min_date, max_date = bounds.iloc[0].min_date, bounds.iloc[0].max_date
except Exception as error:
    st.error("Database unavailable. Start Docker, load the schema and data, then refresh this page.")
    st.code("docker compose up -d && docker compose exec -T db psql -U analyst -d ecommerce -f /project/sql/01_schema.sql")
    st.caption(f"Connection detail: {error}")
    st.stop()
# Convert all dates to Python date objects
min_date = pd.Timestamp(min_date).date()
max_date = pd.Timestamp(max_date).date()

default_start_date = max(
    min_date,
    (pd.Timestamp(max_date) - pd.Timedelta(days=180)).date()
)

date_range = st.sidebar.date_input(
    "Order date",
    value=(default_start_date, max_date),
    min_value=min_date,
    max_value=max_date
)
if not isinstance(date_range, tuple) or len(date_range) != 2:
    st.info("Select a start and end date.")
    st.stop()
start_date, end_date = date_range
end_exclusive = pd.Timestamp(end_date) + pd.Timedelta(days=1)

kpis = query(
    """
    SELECT COUNT(*) AS orders,
           COUNT(*) FILTER (WHERE order_status = 'cancelled') AS cancelled_orders,
           COUNT(*) FILTER (WHERE order_status = 'delivered' AND delivered_ts > estimated_delivery_ts) AS late_orders,
           COALESCE(SUM(freight_value), 0) AS freight
    FROM orders
    WHERE order_purchase_ts >= %s AND order_purchase_ts < %s
    """,
    (start_date, end_exclusive),
).iloc[0]

col1, col2, col3, col4 = st.columns(4)
col1.metric("Orders", f"{int(kpis.orders):,}")
col2.metric("Cancellation rate", f"{100 * kpis.cancelled_orders / max(kpis.orders, 1):.1f}%")
delivered = max(kpis.orders - kpis.cancelled_orders, 1)
col3.metric("Late delivery rate", f"{100 * kpis.late_orders / delivered:.1f}%")
col4.metric("Freight billed", f"₹{float(kpis.freight):,.0f}")

st.subheader("Seller delivery hotspots")
seller_kpis = query(
    """
    SELECT seller_id, category, SUM(order_count) AS orders, ROUND(SUM(gmv), 0) AS gmv,
           ROUND(100.0 * SUM(late_order_items) / NULLIF(SUM(item_count), 0), 2) AS late_delivery_pct
    FROM seller_daily_kpis
    WHERE order_date >= %s AND order_date < %s
    GROUP BY seller_id, category
    HAVING SUM(order_count) >= 5
    ORDER BY late_delivery_pct DESC, gmv DESC
    LIMIT 20
    """,
    (start_date, end_exclusive),
)
st.bar_chart(seller_kpis.set_index("seller_id")["late_delivery_pct"])
st.dataframe(seller_kpis, width="stretch", hide_index=True)

st.subheader("Cancellation leakage by acquisition channel and category")
leakage = query(
    """
    WITH cancelled AS (
      SELECT order_id, customer_id, freight_value
      FROM orders
      WHERE order_status = 'cancelled' AND order_purchase_ts >= %s AND order_purchase_ts < %s
    ), counts AS (
      SELECT oi.order_id, COUNT(*) AS item_count FROM order_items oi
      JOIN cancelled c ON c.order_id = oi.order_id GROUP BY oi.order_id
    )
    SELECT c.acquisition_channel, p.category,
           COUNT(DISTINCT x.order_id) AS cancelled_orders,
           ROUND(SUM(oi.item_price * oi.quantity + x.freight_value / counts.item_count), 0) AS revenue_at_risk
    FROM cancelled x
    JOIN customers c ON c.customer_id = x.customer_id
    JOIN order_items oi ON oi.order_id = x.order_id
    JOIN counts ON counts.order_id = x.order_id
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY c.acquisition_channel, p.category
    ORDER BY revenue_at_risk DESC
    LIMIT 20
    """,
    (start_date, end_exclusive),
)
st.dataframe(leakage, width="stretch", hide_index=True)

st.info("Decision rule: prioritize seller/category pairs with both a high late-delivery rate and meaningful GMV; investigate the largest cancellation-leakage segments before increasing acquisition spend.")
