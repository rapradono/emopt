#!/usr/bin/env bash
# Run a fixed set of EMopt benchmarks and record timing / basic scalar outputs.
#
# Typical usage:
#   scripts/benchmark_solver_stack.sh --label baseline-3.21
#   scripts/benchmark_solver_stack.sh --label after-3.24
#
# The output is a TSV file with one row per benchmark run. Run this script
# before and after a PETSc/SLEPc upgrade to compare stability and runtime.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROFILE="quick"
RUNS=3
NPROC="${EMOPT_BENCHMARK_NPROC:-2}"
TIMEOUT_S="${EMOPT_BENCHMARK_TIMEOUT:-300}"
LABEL=""
RESULTS_DIR="${RESULTS_DIR:-$REPO_ROOT/.example-runs/benchmarks}"

usage() {
  cat <<'EOF'
Usage: benchmark_solver_stack.sh [options]

Options:
  --label NAME       Required label for this benchmark set (e.g. baseline-3.21)
  --profile NAME     quick (default) or full
  --runs N           Number of repeated runs per case (default: 3)
  --nproc N          MPI process count (default: 2)
  --timeout SEC      Per-case timeout in seconds (default: 300)
  --results-dir DIR  Output directory root
  --help             Show this message

Profiles:
  quick
    examples/simple_waveguide/simple_waveguide.py
    examples/waveguide_modes/wg_modes_2D.py
    examples/waveguide_modes/wg_modes_3D.py

  full
    quick profile, plus:
    examples/waveguide_bend/wg_bend.py
    examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py

Notes:
  - Uses the active virtual environment's python if VIRTUAL_ENV is set.
  - Otherwise uses .venv/bin/python from the repo.
  - Writes logs plus a results TSV for later comparison.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --runs) RUNS="$2"; shift 2 ;;
    --nproc) NPROC="$2"; shift 2 ;;
    --timeout) TIMEOUT_S="$2"; shift 2 ;;
    --results-dir) RESULTS_DIR="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$LABEL" ]]; then
  echo "--label is required." >&2
  usage
  exit 1
fi

if [[ "$PROFILE" != "quick" && "$PROFILE" != "full" ]]; then
  echo "Unsupported profile: $PROFILE" >&2
  exit 1
fi

if [[ -n "${VIRTUAL_ENV:-}" ]]; then
  PYTHON_BIN="$VIRTUAL_ENV/bin/python"
else
  PYTHON_BIN="$REPO_ROOT/.venv/bin/python"
fi

if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "Python interpreter not found at $PYTHON_BIN" >&2
  exit 1
fi

if ! command -v mpirun >/dev/null 2>&1; then
  echo "mpirun is required in PATH." >&2
  exit 1
fi

if ! command -v /usr/bin/time >/dev/null 2>&1; then
  echo "/usr/bin/time is required for timing and RSS capture." >&2
  exit 1
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$RESULTS_DIR/${LABEL}_${PROFILE}_${TIMESTAMP}"
LOG_DIR="$RUN_DIR/logs"
RESULTS_TSV="$RUN_DIR/results.tsv"

mkdir -p "$LOG_DIR"
cat > "$RESULTS_TSV" <<'EOF'
label	profile	run_index	script	status	exit_code	elapsed_s	max_rss_kb	scalar_label	scalar_value	log_file
EOF

benchmark_cases() {
  cat <<'EOF'
examples/simple_waveguide/simple_waveguide.py
examples/waveguide_modes/wg_modes_2D.py
examples/waveguide_modes/wg_modes_3D.py
EOF

  if [[ "$PROFILE" == "full" ]]; then
    cat <<'EOF'
examples/waveguide_bend/wg_bend.py
examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py
EOF
  fi
}

extract_scalar() {
  local rel_script="$1"
  local log_file="$2"

  case "$rel_script" in
    examples/waveguide_modes/wg_modes_2D.py)
      local line
      line="$(grep -E '^0 : ' "$log_file" | head -n 1 || true)"
      if [[ -n "$line" ]]; then
        printf 'neff_mode0\t%s\n' "$line"
        return 0
      fi
      ;;
    examples/waveguide_modes/wg_modes_3D.py)
      local value
      value="$(grep -Eo 'Effective index = [0-9eE+.-]+' "$log_file" | head -n 1 | awk '{print $4}' || true)"
      if [[ -n "$value" ]]; then
        printf 'effective_index\t%s\n' "$value"
        return 0
      fi
      ;;
  esac

  printf '\t\n'
}

run_case() {
  local rel_script="$1"
  local run_index="$2"
  local script_path="$REPO_ROOT/$rel_script"
  local script_dir
  local script_name
  local log_file
  local rc
  local status
  local elapsed
  local max_rss
  local scalar_line
  local scalar_label
  local scalar_value

  script_dir="$(dirname "$script_path")"
  script_name="$(basename "$script_path")"
  log_file="$LOG_DIR/$(echo "${run_index}_${rel_script}" | tr '/' '_').log"

  echo "RUN[$run_index] $rel_script"

  set +e
  (
    cd "$script_dir"
    mkdir -p data
    OMP_NUM_THREADS=1 MPLBACKEND=Agg PYTHONPATH="$REPO_ROOT" \
      /usr/bin/time -f '__EMOPT_BENCH__\t%e\t%M' \
      timeout "${TIMEOUT_S}s" \
      mpirun -n "$NPROC" "$PYTHON_BIN" "$script_name"
  ) >"$log_file" 2>&1 </dev/null
  rc=$?
  set -e

  status="PASS"
  if [[ $rc -eq 124 ]]; then
    status="TIMEOUT"
  elif [[ $rc -ne 0 ]]; then
    status="FAIL"
  fi

  elapsed="$(grep '__EMOPT_BENCH__' "$log_file" | tail -n 1 | awk -F'\t' '{print $2}' || true)"
  max_rss="$(grep '__EMOPT_BENCH__' "$log_file" | tail -n 1 | awk -F'\t' '{print $3}' || true)"
  scalar_line="$(extract_scalar "$rel_script" "$log_file")"
  scalar_label="$(printf '%s' "$scalar_line" | awk -F'\t' '{print $1}')"
  scalar_value="$(printf '%s' "$scalar_line" | awk -F'\t' '{print $2}')"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$LABEL" \
    "$PROFILE" \
    "$run_index" \
    "$rel_script" \
    "$status" \
    "$rc" \
    "$elapsed" \
    "$max_rss" \
    "$scalar_label" \
    "$scalar_value" \
    "$log_file" >> "$RESULTS_TSV"
}

echo "Benchmark label : $LABEL"
echo "Profile         : $PROFILE"
echo "Runs per case   : $RUNS"
echo "MPI processes   : $NPROC"
echo "Timeout (sec)   : $TIMEOUT_S"
echo "Python          : $PYTHON_BIN"
echo "Run dir         : $RUN_DIR"
echo

while IFS= read -r rel_script; do
  [[ -n "$rel_script" ]] || continue
  for run_index in $(seq 1 "$RUNS"); do
    run_case "$rel_script" "$run_index"
  done
done < <(benchmark_cases)

echo
echo "Finished benchmark set."
echo "Results: $RESULTS_TSV"
echo
awk -F'\t' 'NR > 1 {c[$5]++} END {for (k in c) print k, c[k]}' "$RESULTS_TSV" | sort
