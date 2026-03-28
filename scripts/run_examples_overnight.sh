#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="${RESULTS_DIR:-$REPO_ROOT/.example-runs}"
NPROC="${EMOPT_EXAMPLE_NPROC:-2}"
TIMEOUT_S="${EMOPT_EXAMPLE_TIMEOUT:-900}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$RESULTS_DIR/$TIMESTAMP"

mkdir -p "$RUN_DIR/logs"
RESULTS_TSV="$RUN_DIR/results.tsv"

echo -e "status\texit_code\tscript" > "$RESULTS_TSV"
echo "Run dir: $RUN_DIR"
echo "NPROC=$NPROC TIMEOUT_S=$TIMEOUT_S"

while IFS= read -r rel_script; do
  script_path="$REPO_ROOT/$rel_script"
  log_file="$RUN_DIR/logs/$(echo "$rel_script" | tr '/' '_').log"
  echo "RUN $rel_script"

  set +e
  (
    cd "$(dirname "$script_path")"
    # Several examples write artifacts to ./data and assume it exists.
    mkdir -p data
    OMP_NUM_THREADS=1 MPLBACKEND=Agg \
      timeout "${TIMEOUT_S}s" \
      mpirun -n "$NPROC" python "$(basename "$script_path")"
  ) >"$log_file" 2>&1 </dev/null
  rc=$?
  set -e

  status="PASS"
  if [[ $rc -eq 124 ]]; then
    status="TIMEOUT"
  elif [[ $rc -ne 0 ]]; then
    status="FAIL"
  fi

  echo -e "${status}\t${rc}\t${rel_script}" >> "$RESULTS_TSV"
done < <(cd "$REPO_ROOT" && find examples -type f -name '*.py' | sort)

echo
echo "Finished."
echo "Results: $RESULTS_TSV"
echo "Logs:    $RUN_DIR/logs"
awk -F'\t' 'NR>1 {c[$1]++} END {for (k in c) print k, c[k]}' "$RESULTS_TSV" | sort
