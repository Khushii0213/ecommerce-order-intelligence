# AI-native, human-reviewed analyst workflow

AI speeds up iteration here; it does not replace data validation or authorization.

## 1. Translate a question into a testable metric

Prompt: `You are a data analyst. Turn this question into a metric definition, required tables, grain, assumptions, and three data-quality checks. Do not write SQL yet: Which seller groups are driving late deliveries?`

Review the proposed grain before querying. For this project, late delivery is evaluated at delivered order-item level because seller is present on an item.

## 2. Review query-plan risks

Prompt: `Review this PostgreSQL EXPLAIN ANALYZE output. Identify the top two bottlenecks, explain whether an index can help, and suggest a semantically equivalent rewrite. Do not suggest changes without explaining their trade-off.`

Validate suggestions by running both queries and comparing row counts and aggregates, not only execution time.

## 3. Convert results into a recommendation

Prompt: `Given these validated KPI results, write a two-sentence operations recommendation. State the metric, scope, likely action, and uncertainty. Do not imply causation from correlation.`

## Guardrails

- Use a read-only role for analysis; never run AI-generated DDL/DML without review.
- Parameterize date and category inputs; do not concatenate UI input into SQL.
- Preserve the baseline query and plan so improvements are auditable.
- Treat AI output as a hypothesis. Reconcile totals to known data before publishing an insight.
