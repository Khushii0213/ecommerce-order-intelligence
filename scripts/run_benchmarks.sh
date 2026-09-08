#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$project_dir/benchmarks"
mkdir -p "$output_dir"

run_sql() {
  local source_file="$1"
  local output_file="$2"
  docker compose -f "$project_dir/docker-compose.yml" exec -T db \
    psql -X -U analyst -d ecommerce -v ON_ERROR_STOP=1 -f "/project/sql/$source_file" \
    > "$output_dir/$output_file"
}

echo "Capturing baseline query plans..."
run_sql "03_baseline_queries.sql" "baseline.txt"
echo "Applying indexes and seller KPI materialized view..."
run_sql "04_optimizations.sql" "optimization_setup.txt"
echo "Capturing optimized query plans..."
run_sql "05_optimized_queries.sql" "optimized.txt"
echo "Saved plans to $output_dir"
