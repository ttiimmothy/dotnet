#!/usr/bin/env bash
set -euo pipefail

# ci-steps.sh
# A simple script to run a sequence of steps and mark successful completion
# using marker files. Useful when upstream build tooling lacks reliable
# incremental up-to-date checks.
#
# Features:
# - Define named steps (command and marker file)
# - Skip steps already marked successful unless --force or --reset is used
# - Atomic marker writes to avoid races (uses tempfile + mv)
# - --status to show which steps are done
# - --reset <step|all> to delete markers and re-run
# - --dry-run to print commands without executing
# - Optional command-hash markers so changes to the command re-run the step
#
# Usage examples:
#   ./ci-steps.sh            # run default steps
#   ./ci-steps.sh --status   # show marker status
#   ./ci-steps.sh --reset all
#   ./ci-steps.sh --force     # ignore markers and run all steps
#
# NOTE: Marker files are under .ci-markers/ by default. Deleting a marker
# makes the step run again. Marker files are small text files containing
# the timestamp and optional command hash.

MARKER_DIR=".ci-markers"
mkdir -p "$MARKER_DIR"

FORCE=0
DRY_RUN=0
SHOW_STATUS=0
RESET=""

usage() {
  cat <<'USAGE'
Usage: ci-steps.sh [--force] [--dry-run] [--status] [--reset <step|all>]

This script runs ordered steps and writes marker files on success. If a
marker exists for a step it will be skipped unless --force or --reset is used.
USAGE
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --status) SHOW_STATUS=1; shift ;;
    --reset) RESET="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

marker_path() {
  local name="$1"
  printf "%s/%s.marker" "$MARKER_DIR" "$name"
}

write_marker() {
  local name="$1" payload="$2"
  local mp
  mp=$(marker_path "$name")
  local tmp
  tmp=$(mktemp --tmpdir "$MARKER_DIR/${name}.marker.XXXX")
  printf "%s\n" "$payload" > "$tmp"
  # atomic move
  mv -f -- "$tmp" "$mp"
}

delete_marker() {
  local name="$1"
  local mp
  mp=$(marker_path "$name")
  if [[ -f "$mp" ]]; then
    rm -f -- "$mp"
  fi
}

is_marked() {
  local name="$1"
  local mp
  mp=$(marker_path "$name")
  [[ -f "$mp" ]]
}

show_status() {
  echo "Markers in $MARKER_DIR:"
  for f in "$MARKER_DIR"/*.marker; do
    [[ -e "$f" ]] || continue
    printf " - %s: %s\n" "$(basename "$f" .marker)" "$(cat "$f" | tr '\n' ' ' )"
  done
}

# Define steps here as: steps+=("name|command|use_command_hash")
# If use_command_hash is 1, the script will include a sha1 of the command
# in the marker so changing the command forces re-run.
steps=()

# Example steps - edit to match your CI sequence. Keep commands idempotent
# or guarded appropriately.
steps+=("prepare-dotnet|./eng/build.sh clr+libs -c Release|1")
steps+=("build-libs|./build.sh libs -rc release|1")
steps+=("run-tests|./test.sh -ci|1")

if [[ $SHOW_STATUS -eq 1 ]]; then
  show_status
  exit 0
fi

if [[ -n "$RESET" ]]; then
  if [[ "$RESET" == "all" ]]; then
    echo "Resetting all markers in $MARKER_DIR"
    rm -f -- "$MARKER_DIR"/*.marker || true
  else
    echo "Resetting marker for: $RESET"
    delete_marker "$RESET"
  fi
  exit 0
fi

for entry in "${steps[@]}"; do
  IFS='|' read -r name cmd use_hash <<< "$entry"

  mp=$(marker_path "$name")

  # compute payload for marker
  if [[ "$use_hash" == "1" ]]; then
    # compute simple hash of the command text
    if command -v sha1sum >/dev/null 2>&1; then
      chash=$(printf "%s" "$cmd" | sha1sum | awk '{print $1}')
    else
      chash=$(printf "%s" "$cmd" | md5sum | awk '{print $1}')
    fi
    payload="done:$(date --iso-8601=seconds) cmdhash:$chash"
  else
    payload="done:$(date --iso-8601=seconds)"
  fi

  if [[ $FORCE -eq 0 && -f "$mp" ]]; then
    if [[ "$use_hash" == "1" ]]; then
      # check stored hash
      stored=$(awk -F'cmdhash:' '{print $2}' "$mp" || true)
      if [[ -n "$stored" && "$stored" == "$chash" ]]; then
        echo "Skipping $name (marker present and command hash matches)"
        continue
      fi
    else
      echo "Skipping $name (marker present)"
      continue
    fi
  fi

  echo "Running step: $name"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: $cmd"
    continue
  fi

  # Run command, capturing exit
  set +e
  bash -lc "$cmd"
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    echo "Step $name failed with exit code $rc"
    exit $rc
  fi

  # write marker
  write_marker "$name" "$payload"
  echo "Marked $name as done"
done

echo "All steps complete"
