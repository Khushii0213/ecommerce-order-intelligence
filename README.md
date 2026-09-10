# E-commerce Order Intelligence & SQL Performance Optimization

A portfolio project for investigating delivery, cancellation, and revenue-leakage questions in a realistic e-commerce marketplace. It demonstrates the analyst workflow: translate business questions into SQL, diagnose bottlenecks with `EXPLAIN ANALYZE`, apply measurable optimizations, and communicate outcomes in a lightweight dashboard.

## 🔗 Live Demo
https://ecommerce-order-intelligence-nynhhgs8uvffgdygwyhjapp.streamlit.app/

## What this demonstrates

- PostgreSQL data modelling for orders, items, payments, customers, sellers, and products
- Large-scale data generation (up to 500k orders with the default Docker workflow)
- Query-plan diagnosis using `EXPLAIN (ANALYZE, BUFFERS)`
- Index design, sargable predicates, pre-aggregation, and materialized views
- Business KPIs for late delivery, cancellation, seller performance, and revenue leakage
- An AI-assisted, human-reviewed SQL workflow with guardrails

## Business questions

1. Which seller/category combinations have the highest late-delivery rate and are materially affecting GMV?
2. Where are cancellations concentrated, and how much potential revenue is at risk?
3. Which customers are likely to churn after a poor delivery experience?
4. Which payment methods have the most failed or duplicated payment events?

## Quick start

Prerequisites: Docker Desktop and Python 3.10+.

```bash
cd ecommerce-order-intelligence
docker compose up -d
docker compose exec -T db psql -U analyst -d ecommerce -f /project/sql/01_schema.sql
docker compose exec -T db psql -U analyst -d ecommerce -v customers=100000 -v sellers=2500 -v products=12000 -v orders=500000 -f /project/sql/02_generate_data.sql
./scripts/run_benchmarks.sh
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
streamlit run dashboard/app.py
```

For a quicker local run, pass `-v orders=50000 -v customers=10000` while loading data.

## Project structure

```text
sql/01_schema.sql              Tables and constraints
sql/02_generate_data.sql       Deterministic, scalable synthetic data
sql/03_baseline_queries.sql    Intentionally inefficient analytical queries
sql/04_optimizations.sql       Indexes and pre-aggregated seller metrics
sql/05_optimized_queries.sql   Equivalent optimized queries
dashboard/app.py               Streamlit stakeholder dashboard
scripts/run_benchmarks.sh      Reproducible EXPLAIN ANALYZE capture
docs/case-study.md             Interview-ready story and measurement template
docs/ai-workflow.md            Safe AI-native analyst workflow
```

## Benchmarking honestly

Do not claim a fixed speed-up from this repository: execution time depends on machine, PostgreSQL configuration, cache state, and chosen scale. Run `scripts/run_benchmarks.sh`; it writes actual plans and timings to `benchmarks/`. The case study shows how to report your own before/after results.

## AI-native workflow

AI is used as a reviewer and accelerator, not as an unchecked query generator. See [docs/ai-workflow.md](docs/ai-workflow.md) for prompts that turn a business question into a tested query, check query-plan risks, and produce stakeholder-friendly recommendations. Every generated query must be read-only, reviewed, and validated against known aggregates before use.

## Resume bullets after you run it

- Built a PostgreSQL e-commerce analytics model spanning **[N] orders** and **[N] order items**, translating delivery, cancellation, and revenue-leakage questions into production-style SQL.
- Diagnosed slow analytical queries with `EXPLAIN ANALYZE`; improved **[query name]** from **[baseline]** to **[optimized]** through sargable date filters, targeted indexes, and pre-aggregated seller KPIs.
- Delivered a Streamlit decision dashboard surfacing late-delivery hotspots, cancellation risk, and seller actions; used an AI-assisted, human-reviewed workflow for query review and insight communication.

Replace bracketed values only with results captured in `benchmarks/`.
