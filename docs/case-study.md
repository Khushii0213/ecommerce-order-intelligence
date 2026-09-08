# Case study: from slow seller dashboard to decision-ready KPI layer

## Problem

Operations leaders need to identify seller/category combinations that are driving late deliveries and protect revenue before customers churn. The original dashboard query joined orders, items, products, and sellers on every refresh. At realistic volume, it became slow and costly.

## Diagnosis

Start with `sql/03_baseline_queries.sql` and inspect its `EXPLAIN (ANALYZE, BUFFERS)` output.

- `DATE(order_purchase_ts)` and `TO_CHAR(order_purchase_ts, ...)` wrap the filtered column, which makes the timestamp predicate non-sargable.
- The dashboard recalculates an item-level aggregation over several large tables on each request.
- The cancellation query repeats order-level freight once for every item, inflating revenue at risk.

## Intervention

1. Replace function-wrapped date predicates with half-open timestamp ranges.
2. Add a composite index on `(order_status, order_purchase_ts)` for the selective filter.
3. Add an order-item join index for the fact-table join pattern.
4. Build `seller_daily_kpis`, a materialized view at the granularity the dashboard requires.
5. Allocate freight across item count before grouping cancellation leakage.

## Measured result

Run `./scripts/run_benchmarks.sh` twice if you want to observe cold and warm cache behavior. Copy actual values from `benchmarks/baseline.txt` and `benchmarks/optimized.txt`; never invent them.

| Query | Baseline execution time | Optimized execution time | Change | What changed |
|---|---:|---:|---:|---|
| Seller delivery hotspots | [record] | [record] | [calculate] | Range filter, indexes, daily KPI view |
| Cancellation leakage | [record] | [record] | [calculate] | Range filter, join strategy, correct freight allocation |

## Business recommendation template

`[Seller/category]` has a late-delivery rate of `[X]%` across `[N]` orders and `[GMV]` GMV. Validate inventory handoff and carrier SLA for this segment first. `[Channel/category]` has `[amount]` cancellation leakage; pause incremental acquisition spend until the driver is understood.

## Interview walkthrough

"I began with ambiguous questions from operations rather than a predefined report. I modeled the operational data in PostgreSQL, generated a scalable test volume, and used query plans to separate a logic issue from a performance issue. I replaced non-sargable predicates, indexed the actual access path, and pre-aggregated the KPI grain used by the dashboard. I then checked that the optimization also corrected the freight-allocation metric, so the faster answer was trustworthy."
