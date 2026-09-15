# 🛒 E-commerce Order Intelligence & SQL Performance Optimization

An end-to-end **data analytics and SQL performance engineering project** built around a realistic e-commerce marketplace.

The project demonstrates how an analyst can move from **business questions → SQL analysis → query-plan diagnosis → database optimization → measurable benchmarking → stakeholder-facing insights**.

It combines **PostgreSQL, advanced SQL, query optimization, synthetic large-scale data generation, and Streamlit** into a complete analytics workflow.

## 🔗 Live Demo

**Streamlit Dashboard:**
https://ecommerce-order-intelligence-nynhhgs8uvffgdygwyhjapp.streamlit.app/

---

## 🎯 Project Objective

E-commerce businesses generate large volumes of transactional data across customers, sellers, products, orders, payments, and deliveries.

The goal of this project is to investigate operational and revenue-related questions such as:

* Where are delivery delays concentrated?
* Which sellers or categories contribute most to late deliveries?
* Where are cancellations creating potential revenue leakage?
* Which customers may be at risk of churn after poor delivery experiences?
* Which payment methods have higher failure or duplication rates?
* How can analytical SQL queries be made faster and more scalable?

The project treats these questions as a real-world **business intelligence + database optimization problem**.

---

## 💼 Business Questions

### 1. Late Delivery Analysis

**Which seller/category combinations have the highest late-delivery rate and are materially affecting GMV?**

The analysis identifies operational hotspots by combining:

* Seller performance
* Product category
* Delivery status
* Order value / GMV
* Late-delivery rate

### 2. Cancellation & Revenue Leakage

**Where are cancellations concentrated, and how much potential revenue is at risk?**

The analysis examines:

* Cancellation volume
* Cancellation rate
* Seller/category concentration
* Potential lost revenue

### 3. Customer Churn Risk

**Which customers are likely to churn after a poor delivery experience?**

Customer behaviour is analyzed using factors such as:

* Previous orders
* Delivery experience
* Order frequency
* Cancellation behaviour
* Recent purchasing activity

### 4. Payment Reliability

**Which payment methods have the highest failed or duplicated payment events?**

Payment transactions are analyzed to identify:

* Failed payments
* Duplicate payment events
* Payment-method-level issues
* Potential transaction leakage

---

# 🏗️ Solution Architecture

```text
                 ┌──────────────────────────┐
                 │   Synthetic Data Engine   │
                 │   Scalable PostgreSQL     │
                 │      Data Generation      │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │       PostgreSQL DB       │
                 │                          │
                 │ Customers                │
                 │ Sellers                  │
                 │ Products                 │
                 │ Orders                   │
                 │ Order Items              │
                 │ Payments                 │
                 └────────────┬─────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
          ┌─────────────────┐   ┌─────────────────┐
          │ Baseline SQL    │   │ Query Plans     │
          │ Queries         │──▶│ EXPLAIN ANALYZE │
          └────────┬────────┘   └────────┬────────┘
                   │                     │
                   │                     ▼
                   │            ┌─────────────────┐
                   │            │ Optimization    │
                   │            │                 │
                   │            │ • Indexes       │
                   │            │ • Sargability   │
                   │            │ • Preaggregation│
                   │            │ • Materialized  │
                   │            │   Metrics       │
                   │            └────────┬────────┘
                   │                     │
                   └──────────┬──────────┘
                              ▼
                 ┌──────────────────────────┐
                 │   Optimized SQL Queries  │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │     Streamlit Dashboard  │
                 │                          │
                 │ • KPIs                   │
                 │ • Seller Analysis        │
                 │ • Cancellation Analysis  │
                 │ • Revenue Leakage        │
                 │ • Customer Insights      │
                 └──────────────────────────┘
```

---

# 🧰 Tech Stack

| Category             | Technologies                                   |
| -------------------- | ---------------------------------------------- |
| Database             | PostgreSQL                                     |
| Query Language       | SQL                                            |
| Performance Analysis | `EXPLAIN (ANALYZE, BUFFERS)`                   |
| Dashboard            | Streamlit                                      |
| Programming          | Python                                         |
| Containerization     | Docker / Docker Compose                        |
| Data Generation      | PostgreSQL SQL functions                       |
| Analytics            | Aggregations, joins, CTEs, window functions    |
| Optimization         | Indexing, sargable predicates, pre-aggregation |
| Version Control      | Git / GitHub                                   |

---

# 📊 Database Model

The project models a marketplace-style transactional database containing:

```text
Customers
    │
    └────── Orders
               │
               ├────── Order Items ────── Products
               │
               └────── Payments

Sellers ───────────── Products
```

### Core entities

* **Customers** — customer and acquisition information
* **Sellers** — seller-level marketplace information
* **Products** — products and categories
* **Orders** — order timestamps, status, delivery information and freight
* **Order Items** — products, quantities and prices associated with orders
* **Payments** — payment events and payment methods

Primary keys and foreign-key relationships are used to maintain referential integrity.

---

# 🚀 Large-Scale Synthetic Dataset

The project includes deterministic SQL-based data generation designed to scale the marketplace dataset.

The default Docker workflow can generate:

* **100,000 customers**
* **2,500 sellers**
* **12,000 products**
* **500,000 orders**

A smaller dataset can be used for faster local development.

Example:

```bash
docker compose exec -T db psql \
  -U analyst \
  -d ecommerce \
  -v customers=10000 \
  -v sellers=500 \
  -v products=3000 \
  -v orders=50000 \
  -f /project/sql/02_generate_data.sql
```

This allows the same analytical workflow to be tested at different data scales.

---

# ⚡ SQL Performance Optimization

A major focus of the project is understanding **why an analytical query is slow**, rather than simply rewriting SQL until it appears faster.

The workflow is:

```text
Business Question
       ↓
Baseline SQL Query
       ↓
EXPLAIN (ANALYZE, BUFFERS)
       ↓
Identify Bottleneck
       ↓
Optimization
       ↓
Run Equivalent Query
       ↓
Compare Execution Plans
       ↓
Measure Actual Performance
```

## Optimization Techniques

### 1. Index Design

Indexes are created around frequently filtered or joined columns.

For example, order analysis can benefit from indexes involving:

```sql
order_status
order_purchase_ts
```

This allows PostgreSQL to avoid scanning the entire orders table when a query targets a specific status and date range.

---

### 2. Sargable Predicates

A common optimization is avoiding functions on indexed columns inside filtering conditions.

Instead of:

```sql
WHERE TO_CHAR(order_purchase_ts, 'YYYY-MM') 
      BETWEEN '2025-01' AND '2025-06'
```

the optimized approach uses a timestamp range:

```sql
WHERE order_purchase_ts >= '2025-01-01'
  AND order_purchase_ts < '2025-07-01'
```

This makes the predicate more index-friendly and allows PostgreSQL to use an appropriate index efficiently.

---

### 3. Pre-Aggregation

Repeatedly calculating seller-level metrics from raw transactional data can become expensive.

The project therefore uses pre-aggregated seller metrics where appropriate.

This reduces repeated joins and aggregations when the dashboard requests the same business-level KPIs multiple times.

---

### 4. Materialized Metrics

Frequently used analytical metrics can be persisted in a materialized structure rather than recalculated from the entire transactional dataset for every dashboard request.

This creates a separation between:

```text
Raw Transactional Data
          ↓
Analytical Aggregation
          ↓
Dashboard-Ready Metrics
```

---

# 🔍 Query Plan Analysis

The project uses:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

rather than relying only on query execution time.

This makes it possible to inspect:

* Sequential scans
* Index scans
* Bitmap scans
* Join strategies
* Sort operations
* Aggregation cost
* Rows estimated vs. rows actually processed
* Buffer hits / reads
* Planning time
* Execution time

Example workflow:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
```

The resulting plans are stored in the `benchmarks/` directory.

---

# 📈 Benchmarking

The repository includes reproducible benchmark scripts.

Run:

```bash
./scripts/run_benchmarks.sh
```

Benchmark outputs are written to:

```text
benchmarks/
├── baseline.txt
├── optimized.txt
└── optimization_setup.txt
```

### Important

Execution time is **environment-dependent**.

Results can vary based on:

* Hardware
* PostgreSQL configuration
* Dataset size
* Cache state
* Available memory
* Query planner decisions
* Database statistics

Therefore, the project does **not** claim a universal fixed speed-up.

The correct approach is to run the benchmark locally and report the actual before/after measurements from that environment.

---

# 📊 Streamlit Dashboard

The project includes a lightweight stakeholder-facing dashboard built with Streamlit.

The dashboard converts database analysis into business-oriented views such as:

* Overall marketplace KPIs
* Late-delivery performance
* Seller/category analysis
* Cancellation concentration
* Revenue leakage indicators
* Customer behaviour insights
* Payment reliability

The goal is to make the output understandable to a stakeholder who does not need to read the underlying SQL.

---

# 🤖 AI-Assisted SQL Workflow

The project also demonstrates a controlled AI-assisted analyst workflow.

AI can assist with:

```text
Business Question
       ↓
AI-generated SQL Draft
       ↓
Human Review
       ↓
Schema / Logic Validation
       ↓
EXPLAIN ANALYZE
       ↓
Performance Testing
       ↓
Approved Query
       ↓
Dashboard / Reporting
```

AI-generated SQL is **not treated as automatically trusted**.

Human review and database validation remain necessary to check:

* Business logic
* Table relationships
* Join correctness
* Metric definitions
* Filtering logic
* Performance
* Data leakage / unintended results

Additional details are available in:

```text
docs/ai-workflow.md
```

---

# 📁 Project Structure

```text
ecommerce-order-intelligence/
│
├── sql/
│   ├── 01_schema.sql
│   ├── 02_generate_data.sql
│   ├── 03_baseline_queries.sql
│   ├── 04_optimizations.sql
│   └── 05_optimized_queries.sql
│
├── dashboard/
│   └── app.py
│
├── scripts/
│   └── run_benchmarks.sh
│
├── benchmarks/
│   ├── baseline.txt
│   ├── optimized.txt
│   └── optimization_setup.txt
│
├── docs/
│   ├── case-study.md
│   └── ai-workflow.md
│
├── output/
│   └── Order Intelligence.pdf
│
├── docker-compose.yml
├── requirements.txt
├── .gitignore
└── README.md
```

---

# 🛠️ Quick Start

## Prerequisites

Install:

* Docker Desktop
* Python 3.10+
* Git

## 1. Clone the repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd ecommerce-order-intelligence
```

## 2. Start PostgreSQL

```bash
docker compose up -d
```

## 3. Create the database schema

```bash
docker compose exec -T db \
  psql -U analyst -d ecommerce \
  -f /project/sql/01_schema.sql
```

## 4. Generate the dataset

```bash
docker compose exec -T db \
  psql -U analyst -d ecommerce \
  -v customers=100000 \
  -v sellers=2500 \
  -v products=12000 \
  -v orders=500000 \
  -f /project/sql/02_generate_data.sql
```

For a faster local test:

```bash
-v customers=10000 -v orders=50000
```

## 5. Run SQL benchmarks

```bash
./scripts/run_benchmarks.sh
```

## 6. Create Python environment

```bash
python -m venv .venv
source .venv/bin/activate
```

Windows:

```bash
.venv\Scripts\activate
```

## 7. Install dependencies

```bash
pip install -r requirements.txt
```

## 8. Launch the dashboard

```bash
streamlit run dashboard/app.py
```

The Streamlit application will open locally in your browser.

---

# 📌 Key Learning Outcomes

This project demonstrates practical experience with:

### SQL & Databases

* Complex joins
* Aggregations
* CTEs
* Window functions
* Date/time filtering
* PostgreSQL schema design
* Primary and foreign keys
* Index design
* Materialized/pre-aggregated analytical data

### Performance Engineering

* `EXPLAIN ANALYZE`
* Buffer analysis
* Query-plan interpretation
* Sequential vs. index scans
* Sargable predicates
* Join optimization
* Benchmarking before and after optimization

### Business Analytics

* KPI design
* GMV analysis
* Seller performance
* Delivery operations
* Cancellation analysis
* Revenue leakage
* Customer churn indicators
* Payment reliability

### Data Products

* Streamlit dashboards
* Stakeholder-focused visualization
* Reproducible analytical workflows
* AI-assisted SQL with human validation

---



---

# 🔗 Project Links

**Live Dashboard:**
https://ecommerce-order-intelligence-nynhhgs8uvffgdygwyhjapp.streamlit.app/


---
